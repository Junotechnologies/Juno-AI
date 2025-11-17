#!/bin/bash

# Deploy TENS Prediction API to Google Cloud Functions

# Set your project ID
PROJECT_ID="junoplus-dev"
REGION="us-central1"
FUNCTION_NAME="predict-tens-level"

echo "🚀 Deploying TENS Prediction API to Cloud Functions..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Function: $FUNCTION_NAME"

# Deploy the function
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime python311 \
  --region $REGION \
  --source . \
  --entry-point predict_tens_level \
  --trigger-http \
  --allow-unauthenticated \
  --memory 512MB \
  --timeout 60s \
  --set-env-vars PROJECT_ID=$PROJECT_ID

if [ $? -eq 0 ]; then
    echo "✅ Function deployed successfully!"
    echo ""
    echo "🌐 Function URL:"
    gcloud functions describe $FUNCTION_NAME --region $REGION --gen2 --format "value(serviceConfig.uri)"
    echo ""
    echo "📝 API Usage Example:"
    echo "curl -X POST https://YOUR_FUNCTION_URL \\
  -H 'Content-Type: application/json' \\
  -d '{
    \"user_age\": 28,
    \"user_cycle_length\": 30,
    \"user_period_length\": 5,
    \"is_period_day\": true,
    \"is_ovulation_day\": false,
    \"current_pain_level\": 8,
    \"current_flow_level\": 3,
    \"has_medications\": true,
    \"medication_count\": 2,
    \"user_experience\": \"experienced_user\",
    \"time_of_day\": \"afternoon\",
    \"previous_tens_level\": 5
  }'"
else
    echo "❌ Deployment failed!"
    exit 1
fi