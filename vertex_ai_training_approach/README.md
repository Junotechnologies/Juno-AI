# Vertex AI ML Training Approach

## 📋 Overview

This approach leverages Google Cloud Vertex AI and BigQuery ML for serverless, scalable machine learning. It uses BigQuery's native ML capabilities to train models directly on data stored in BigQuery, with seamless integration to Vertex AI for experiment tracking and deployment.

## 🎯 What This Approach Predicts

- **TENS Level** (0-10): Primary focus on TENS therapy level prediction
- **Heat Level** (0-3): Heuristic-based recommendations (separate model optional)
- **TENS Mode** (0-3): Integrated into recommendation logic

## 🏗️ Architecture

### Cloud-Native ML Pipeline
```
BigQuery Data Warehouse
    ↓
BigQuery ML Training
    ├── LINEAR_REG (baseline)
    └── BOOSTED_TREE_REGRESSOR (production)
    ↓
Vertex AI Experiments (tracking)
    ↓
BigQuery TABLE FUNCTION (serving)
    ↓
Flutter Backend API
```

## 🚀 Current Performance (Version 2.0)

### Best Boosted Tree Model
| Dataset | MAE | R² Score | RMSE |
|---------|-----|----------|------|
| EVAL | **1.12** | **0.79** | **1.48** |
| TEST | **1.18** | **0.76** | **1.53** |

### Improvement over v1.0
- MAE: **22% reduction** (1.52 → 1.18)
- R²: **19% increase** (0.64 → 0.76)

## 📂 Files

- `vertex_ai_ml_training.ipynb` - Main training and deployment notebook
- `IMPROVEMENTS_REPORT.md` - Detailed version history
- BigQuery Models:
  - `junoplus-dev.junoplus_analytics.tens_level_predictor_vertex_v2`
  - `junoplus-dev.junoplus_analytics.get_intelligent_tens_recommendation` (TABLE FUNCTION)

## 🔑 Key Features

### Vertex AI Integration
- Native BigQuery connectivity
- Automated experiment tracking
- Hyperparameter tuning with grid search
- Model versioning and registry

### Advanced Capabilities
- User-stable data splitting (FARM_FINGERPRINT)
- User preference features (avg, mode TENS levels)
- Intelligent imputation for missing values
- Confidence scoring based on input completeness
- Fallback to heuristics when model unavailable

### Production Features
- **TABLE FUNCTION**: SQL-based inference
- **Personalized Explanations**: Context-aware recommendations
- **Confidence Scores**: 0.6-0.95 based on data quality
- **Missing Data Handling**: User-specific and global fallbacks

## 💡 Advantages

✅ **Serverless Training** - No infrastructure management  
✅ **BigQuery Integration** - No data movement required  
✅ **Scalable Inference** - Handles thousands of requests/second  
✅ **Cost-Effective** - Pay-per-query pricing  
✅ **Experiment Tracking** - Built-in Vertex AI integration  
✅ **Production-Ready** - Direct SQL access from backend  

## ⚠️ Limitations

- BigQuery ML has limited model types compared to full TensorFlow
- Hyperparameter space smaller than custom frameworks
- Less control over neural network architectures
- Primarily focused on single-output predictions (TENS Level)
- New user cold-start challenges

## 🎓 When to Use This Approach

**Best for:**
- Cloud-native deployment on Google Cloud Platform
- Large-scale data stored in BigQuery
- Serverless ML requirements
- Fast iteration and experimentation
- Teams familiar with SQL

**Not ideal for:**
- On-premise deployment
- Complex deep learning architectures
- Multi-output unified models
- When offline inference is required

## 📊 Training Data

- **User-Stable Split**: 80% train, 10% eval, 10% test
- **Split Method**: FARM_FINGERPRINT on userId (deterministic)
- **Quality Filter**: high_quality and medium_quality sessions
- **Feature Count**: 14 input features

## 🔧 Usage

### Training a New Model
```python
from google.cloud import bigquery

client = bigquery.Client(project='junoplus-dev')

# Define training query
train_query = """
CREATE OR REPLACE MODEL `junoplus-dev.junoplus_analytics.tens_model_v3`
OPTIONS(
  model_type='BOOSTED_TREE_REGRESSOR',
  input_label_cols=['target_tens_level'],
  data_split_method='CUSTOM',
  data_split_col='is_train',
  learn_rate=0.1,
  max_iterations=50
) AS
SELECT * FROM `junoplus-dev.junoplus_analytics.ml_training_data`
WHERE is_train = TRUE
"""

job = client.query(train_query)
job.result()
```

### Making Predictions
```python
# Use TABLE FUNCTION for predictions
predict_query = """
SELECT * FROM `junoplus-dev.junoplus_analytics.get_intelligent_tens_recommendation`(
  NULL,  -- user_id (NULL for anonymous)
  28,    -- user_age
  30,    -- user_cycle_length
  5,     -- user_period_length
  true,  -- is_period_day
  false, -- is_ovulation_day
  NULL,  -- current_pain_level (NULL triggers imputation)
  NULL,  -- current_flow_level
  true,  -- has_medications
  2,     -- medication_count
  'experienced_user',
  'afternoon',
  5,     -- previous_tens_level
  'continuous'
)
"""

result = client.query(predict_query).to_dataframe()
print(result)
```

### Flutter Backend Integration
```dart
// Call from Flutter backend
final query = '''
SELECT 
  recommended_tens_level,
  recommended_heat_level,
  confidence_score,
  recommendation_explanation
FROM `junoplus-dev.junoplus_analytics.get_intelligent_tens_recommendation`(
  @userId, @userAge, @cycleLength, @periodLength,
  @isPeriodDay, @isOvulationDay, @painLevel, @flowLevel,
  @hasMedications, @medicationCount, @userExperience,
  @timeOfDay, @previousTensLevel, @tensMode
)
''';

// Execute via BigQuery API
```

## 📈 Feature Importance (Top 10)

1. `user_avg_tens_level` - 24%
2. `period_pain_level` - 18%
3. `input_pain_level` - 15%
4. `user_mode_tens_level` - 12%
5. `is_period_day` - 8%
6. `has_pain_medication` - 6%
7. `medication_count` - 5%
8. `days_since_signup` - 4%
9. `session_hour` - 3%
10. `cycle_length` - 3%

## 📈 Next Steps

See `IMPROVEMENTS_REPORT.md` for:
- Multi-output model plans
- Cold-start handling strategies
- Time-series feature engineering
- DNN_REGRESSOR experiments
- Automated retraining pipeline
