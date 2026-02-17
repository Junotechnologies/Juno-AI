#!/bin/bash

# Deploy ML Snapshot Creation Function
# Creates weekly snapshots of ml_training_base_v2

set -e

PROJECT_ID="junoplus-dev"
REGION="us-central1"
FUNCTION_NAME="create-ml-snapshot"
TOPIC_NAME="create-ml-snapshot"

echo "🚀 Deploying ML Snapshot Function"
echo "=================================="
echo ""

# 1. Create Pub/Sub topic if it doesn't exist
echo "1️⃣  Creating Pub/Sub topic: ${TOPIC_NAME}"
gcloud pubsub topics create ${TOPIC_NAME} \
  --project=${PROJECT_ID} 2>/dev/null || echo "   Topic already exists"

# 2. Deploy Cloud Function
echo ""
echo "2️⃣  Deploying Cloud Function: ${FUNCTION_NAME}"
gcloud functions deploy ${FUNCTION_NAME} \
  --gen2 \
  --runtime=python311 \
  --region=${REGION} \
  --source=./functions/create_ml_snapshot \
  --entry-point=create_ml_snapshot \
  --trigger-topic=${TOPIC_NAME} \
  --timeout=540s \
  --memory=512MB \
  --service-account=refresh-functions@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID}

# 3. Create Cloud Scheduler job (Sundays at 4 AM UTC, after gold refresh)
echo ""
echo "3️⃣  Creating Cloud Scheduler job"
gcloud scheduler jobs create pubsub create-ml-snapshot-weekly \
  --location=${REGION} \
  --schedule="0 4 * * 0" \
  --topic=${TOPIC_NAME} \
  --message-body='{"trigger":"scheduled"}' \
  --time-zone="UTC" \
  --description="Create weekly ML dataset snapshot (Sundays 4 AM UTC)" \
  --project=${PROJECT_ID} 2>/dev/null || \
gcloud scheduler jobs update pubsub create-ml-snapshot-weekly \
  --location=${REGION} \
  --schedule="0 4 * * 0" \
  --topic=${TOPIC_NAME} \
  --message-body='{"trigger":"scheduled"}' \
  --time-zone="UTC" \
  --description="Create weekly ML dataset snapshot (Sundays 4 AM UTC)" \
  --project=${PROJECT_ID}

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📊 Configuration:"
echo "   Function: ${FUNCTION_NAME}"
echo "   Schedule: Every Sunday at 4:00 AM UTC"
echo "   Topic: ${TOPIC_NAME}"
echo "   Runtime: Python 3.11"
echo "   Memory: 512MB"
echo "   Timeout: 540s (9 min)"
echo ""
echo "🧪 Test manually:"
echo "   gcloud pubsub topics publish ${TOPIC_NAME} --project=${PROJECT_ID} --message='test'"
echo ""
echo "📋 View logs:"
echo "   gcloud functions logs read ${FUNCTION_NAME} --region=${REGION} --project=${PROJECT_ID} --limit=50"
echo ""
echo "📅 Next scheduled run:"
gcloud scheduler jobs describe create-ml-snapshot-weekly \
  --location=${REGION} \
  --project=${PROJECT_ID} \
  --format="value(schedule)" | \
  xargs -I {} echo "   Every Sunday at 4:00 AM UTC (cron: {})"
