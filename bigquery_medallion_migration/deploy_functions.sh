#!/bin/bash
# Deploy all Cloud Functions for JunoAI data platform automation
# This script deploys Cloud Functions Gen2 and sets up Cloud Scheduler

set -e

PROJECT_ID="junoplus-dev"
REGION="us-central1"

echo "🚀 Deploying Cloud Functions for JunoAI Data Platform"
echo "="*80
echo ""
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Timestamp: $(date)"
echo ""

# Check if gcloud is authenticated
echo "🔐 Checking authentication..."
gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Not authenticated. Please run: gcloud auth login"
    exit 1
fi
echo "✅ Authenticated"
echo ""

# Set project
echo "📋 Setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID
echo ""

# Create service account for Cloud Functions
echo "🔐 Setting up service account for Cloud Functions..."
SERVICE_ACCOUNT_NAME="refresh-functions"
SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Check if service account exists
if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project=$PROJECT_ID &>/dev/null; then
    echo "  Creating service account: $SERVICE_ACCOUNT_EMAIL"
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="Service account for refresh functions" \
        --project=$PROJECT_ID
    echo "  ✅ Service account created"
else
    echo "  ℹ️  Service account already exists"
fi

# Grant BigQuery Editor role
echo "  Granting BigQuery Editor role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/bigquery.editor" \
    --condition=None \
    --quiet 2>/dev/null || echo "  ℹ️  Role binding already exists or updated"

# Grant Pub/Sub Publisher role  
echo "  Granting Pub/Sub Publisher role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/pubsub.publisher" \
    --condition=None \
    --quiet 2>/dev/null || echo "  ℹ️  Role binding already exists or updated"

echo "✅ Service account configured"
echo ""

# Enable required APIs
echo "🔌 Enabling required APIs..."
gcloud services enable cloudfunctions.googleapis.com \
  cloudscheduler.googleapis.com \
  pubsub.googleapis.com \
  cloudbuild.googleapis.com \
  --project=$PROJECT_ID
echo "✅ APIs enabled"
echo ""

# Create Pub/Sub topics if they don't exist
echo "📢 Creating Pub/Sub topics..."
gcloud pubsub topics create refresh-silver --project=$PROJECT_ID 2>/dev/null && echo "  ✅ Created refresh-silver topic" || echo "  ℹ️  refresh-silver topic already exists"
gcloud pubsub topics create refresh-gold --project=$PROJECT_ID 2>/dev/null && echo "  ✅ Created refresh-gold topic" || echo "  ℹ️  refresh-gold topic already exists"
gcloud pubsub topics create quality-check --project=$PROJECT_ID 2>/dev/null && echo "  ✅ Created quality-check topic" || echo "  ℹ️  quality-check topic already exists"
echo ""

# 1. Deploy Silver Refresh Function
echo "="*80
echo "1️⃣  Deploying refresh-silver-layer function..."
echo "="*80
gcloud functions deploy refresh-silver-layer \
  --gen2 \
  --runtime=python311 \
  --region=$REGION \
  --source=functions/refresh_silver \
  --entry-point=refresh_silver \
  --trigger-topic=refresh-silver \
  --timeout=540s \
  --memory=512MB \
  --project=$PROJECT_ID \
  --service-account=refresh-functions@$PROJECT_ID.iam.gserviceaccount.com \
  --ingress-settings=internal-only

if [ $? -eq 0 ]; then
    echo "✅ refresh-silver-layer deployed"
else
    echo "❌ Failed to deploy refresh-silver-layer"
    exit 1
fi
echo ""

# 2. Deploy Gold Refresh Function
echo "="*80
echo "2️⃣  Deploying refresh-gold-layer function..."
echo "="*80
gcloud functions deploy refresh-gold-layer \
  --gen2 \
  --runtime=python311 \
  --region=$REGION \
  --source=functions/refresh_gold \
  --entry-point=refresh_gold \
  --trigger-topic=refresh-gold \
  --memory=1024MB \
  --timeout=540s \
  --service-account=refresh-functions@$PROJECT_ID.iam.gserviceaccount.com \
  --ingress-settings=internal-only \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
    echo "✅ refresh-gold-layer deployed"
else
    echo "❌ Failed to deploy refresh-gold-layer"
    exit 1
fi
echo ""

# 3. Deploy Quality Check Function
echo "="*80
echo "3️⃣  Deploying quality-check function..."
echo "="*80
gcloud functions deploy quality-check \
  --gen2 \
  --runtime=python311 \
  --region=$REGION \
  --source=functions/quality_check \
  --entry-point=quality \
  --service-account=refresh-functions@$PROJECT_ID.iam.gserviceaccount.com \
  --ingress-settings=internal-only_check \
  --trigger-topic=quality-check \
  --timeout=300s \
  --memory=512MB \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
    echo "✅ quality-check deployed"
else
    echo "❌ Failed to deploy quality-check"
    exit 1
fi
echo ""

# 4. Schedule Silver Refresh (Daily 2 AM UTC)
echo "="*80
echo "4️⃣  Scheduling silver refresh (daily 2 AM UTC)..."
echo "="*80
gcloud scheduler jobs create pubsub refresh-silver-daily \
  --location=$REGION \
  --schedule="0 2 * * *" \
  --topic=refresh-silver \
  --message-body='{"trigger":"scheduled"}' \
  --time-zone="UTC" \
  --project=$PROJECT_ID 2>/dev/null && echo "✅ Created refresh-silver-daily job" || \
gcloud scheduler jobs update pubsub refresh-silver-daily \
  --location=$REGION \
  --schedule="0 2 * * *" \
  --project=$PROJECT_ID && echo "✅ Updated refresh-silver-daily job"
echo ""

# 5. Schedule Gold Refresh (Weekly Sunday 3 AM UTC)
echo "="*80
echo "5️⃣  Scheduling gold refresh (weekly Sunday 3 AM UTC)..."
echo "="*80
gcloud scheduler jobs create pubsub refresh-gold-weekly \
  --location=$REGION \
  --schedule="0 3 * * 0" \
  --topic=refresh-gold \
  --message-body='{"trigger":"scheduled"}' \
  --time-zone="UTC" \
  --project=$PROJECT_ID 2>/dev/null && echo "✅ Created refresh-gold-weekly job" || \
gcloud scheduler jobs update pubsub refresh-gold-weekly \
  --location=$REGION \
  --schedule="0 3 * * 0" \
  --project=$PROJECT_ID && echo "✅ Updated refresh-gold-weekly job"
echo ""

# 6. Schedule Quality Checks (Hourly)
echo "="*80
echo "6️⃣  Scheduling quality checks (hourly)..."
echo "="*80
gcloud scheduler jobs create pubsub quality-check-hourly \
  --location=$REGION \
  --schedule="0 * * * *" \
  --topic=quality-check \
  --message-body='{"trigger":"scheduled"}' \
  --time-zone="UTC" \
  --project=$PROJECT_ID 2>/dev/null && echo "✅ Created quality-check-hourly job" || \
gcloud scheduler jobs update pubsub quality-check-hourly \
  --location=$REGION \
  --schedule="0 * * * *" \
  --project=$PROJECT_ID && echo "✅ Updated quality-check-hourly job"
echo ""

# Summary
echo "="*80
echo "✅ DEPLOYMENT COMPLETE!"
echo "="*80
echo ""
echo "📊 Deployed Functions:"
echo "  • refresh-silver-layer (Daily 2 AM UTC)"
echo "  • refresh-gold-layer (Weekly Sunday 3 AM UTC)"
echo "  • quality-check (Hourly)"
echo ""
echo "🔍 View deployed functions:"
echo "  gcloud functions list --project=$PROJECT_ID --gen2"
echo ""
echo "📅 View scheduled jobs:"
echo "  gcloud scheduler jobs list --project=$PROJECT_ID --location=$REGION"
echo ""
echo "🧪 Test functions manually:"
echo "  # Trigger silver refresh"
echo "  gcloud scheduler jobs run refresh-silver-daily --location=$REGION"
echo ""
echo "  # Trigger gold refresh"
echo "  gcloud scheduler jobs run refresh-gold-weekly --location=$REGION"
echo ""
echo "  # Trigger quality check"
echo "  gcloud scheduler jobs run quality-check-hourly --location=$REGION"
echo ""
echo "📊 Monitor function logs:"
echo "  gcloud functions logs read refresh-silver-layer --gen2 --region=$REGION --limit=50"
echo "  gcloud functions logs read refresh-gold-layer --gen2 --region=$REGION --limit=50"
echo "  gcloud functions logs read quality-check --gen2 --region=$REGION --limit=50"
echo ""
echo "🎉 Your data platform is now fully automated!"
