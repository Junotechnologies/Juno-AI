# TENS Prediction API

This Cloud Function provides an HTTP API for the TENS level prediction model trained on Vertex AI.

## Deployment

1. Make sure you have the Google Cloud SDK installed and authenticated:
   ```bash
   gcloud auth login
   gcloud config set project junoplus-dev
   ```

2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

## API Usage

### Endpoint
```
POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/predict-tens-level
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "user_id": "optional_user_id",
  "user_age": 28,
  "user_cycle_length": 30,
  "user_period_length": 5,
  "is_period_day": true,
  "is_ovulation_day": false,
  "current_pain_level": 8,
  "current_flow_level": 3,
  "has_medications": true,
  "medication_count": 2,
  "user_experience": "experienced_user",
  "time_of_day": "afternoon",
  "previous_tens_level": 5,
  "tens_mode": "continuous"
}
```

### Parameters

| Parameter | Type | Required | Description | Validation |
|-----------|------|----------|-------------|------------|
| `user_id` | string | No | Unique user identifier | Optional |
| `user_age` | integer | Yes | User's age in years | 13-80 |
| `user_cycle_length` | integer | Yes | Length of menstrual cycle in days | 21-45 |
| `user_period_length` | integer | Yes | Length of period in days | 2-10 |
| `is_period_day` | boolean | Yes | Whether today is a period day | true/false |
| `is_ovulation_day` | boolean | Yes | Whether today is ovulation day | true/false |
| `current_pain_level` | integer | No | Current pain level (0-10) | 0-10 or null |
| `current_flow_level` | integer | No | Current flow level (0-5) | 0-5 or null |
| `has_medications` | boolean | Yes | Whether user is taking pain medication | true/false |
| `medication_count` | integer | Yes | Number of medications | >= 0 |
| `user_experience` | string | Yes | User experience level | "new_user", "learning_user", "experienced_user" |
| `time_of_day` | string | Yes | Time of day | "morning", "afternoon", "evening", "night" |
| `previous_tens_level` | integer | Yes | Previous TENS level setting | 0-10 |
| `tens_mode` | string | Yes | TENS stimulation mode | "continuous", "burst", "modulation", "strength" |

### Response

#### Success Response (200)
```json
{
  "recommended_tens_mode": 1,
  "recommended_tens_level": 5,
  "recommended_heat_level": 3,
  "confidence_score": 0.95,
  "recommendation_explanation": "Low intensity TENS recommended for severe period pain",
  "additional_guidance": "Consider combining with heat therapy for enhanced relief",
  "context_used": {
    "is_period_day": true,
    "is_ovulation_day": false,
    "current_pain_level": 8,
    "has_medications": true,
    "user_experience": "experienced_user",
    "time_of_day": "afternoon",
    "tens_mode": "continuous",
    "predicted_mode": 1
  },
  "prediction_timestamp": "2025-01-01T00:00:00.000000",
  "model_version": "hierarchical_vertex_ai_models",
  "raw_mode_prediction": 1,
  "raw_tens_prediction": 5.149,
  "raw_heat_prediction": 3
}
```

#### Error Response (400/500)
```json
{
  "error": "Error description"
}
```

### Testing

You can test the API using curl:

```bash
curl -X POST https://YOUR_FUNCTION_URL \
  -H 'Content-Type: application/json' \
  -d '{
    "user_age": 28,
    "user_cycle_length": 30,
    "user_period_length": 5,
    "is_period_day": true,
    "is_ovulation_day": false,
    "current_pain_level": 8,
    "current_flow_level": 3,
    "has_medications": true,
    "medication_count": 2,
    "user_experience": "experienced_user",
    "time_of_day": "afternoon",
    "previous_tens_level": 5,
    "tens_mode": "continuous"
  }'
```

### Integration with Flutter App

In your Flutter app, you can call this API from your backend or directly from the mobile app:

```dart
// Example Flutter integration
Future<Map<String, dynamic>> getTensRecommendation(Map<String, dynamic> userData) async {
  final response = await http.post(
    Uri.parse('https://YOUR_FUNCTION_URL'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(userData),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Access hierarchical recommendations
    int tensMode = data['recommended_tens_mode'];        // 0-3
    int tensLevel = data['recommended_tens_level'];      // 0-10 (0 if mode=0)
    int heatLevel = data['recommended_heat_level'];      // 0-3
    double confidence = data['confidence_score'];
    String explanation = data['recommendation_explanation'];
    
    return data;
  } else {
    throw Exception('Failed to get recommendation: ${response.body}');
  }
}
```

### Integration Notes

The API now supports hierarchical prediction where:
1. **Mode Prediction**: First predicts the optimal TENS mode (0-3) based on user context
2. **Conditional Level Prediction**: If mode = 0, TENS level = 0 (therapy off). If mode > 0, predicts optimal intensity level (1-10)
3. **Heat Prediction**: Provides complementary heat therapy recommendations

**Mode Values:**
- `0`: TENS therapy not recommended (level will be 0)
- `1`: Low intensity TENS
- `2`: Medium intensity TENS  
- `3`: High intensity TENS

### Security Notes

- The function is currently set to allow unauthenticated access for development
- For production, consider implementing authentication (API keys, JWT tokens, etc.)
- The function has CORS enabled for web applications
- BigQuery access is handled via the Cloud Function's service account

### Monitoring

Monitor your function usage and performance in the Google Cloud Console:
- Go to Cloud Functions
- Select your function
- View logs, metrics, and usage statistics