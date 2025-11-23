# Juno AI - TENS & Heat Therapy Intelligent Prediction System

## 📋 Table of Contents
- [Overview](#overview)
- [Project Architecture](#project-architecture)
- [Machine Learning Approaches](#machine-learning-approaches)
- [Data Pipeline & Feature Engineering](#data-pipeline--feature-engineering)
- [API Architecture](#api-architecture)
- [Deployment Guide](#deployment-guide)
- [API Usage & Integration](#api-usage--integration)
- [Model Performance](#model-performance)
- [Development & Testing](#development--testing)

---

## 🎯 Overview

The Juno AI system provides intelligent, personalized recommendations for TENS (Transcutaneous Electrical Nerve Stimulation) and heat therapy settings for menstrual pain management. The system uses machine learning models trained on real user therapy session data to predict optimal device settings based on individual user context, menstrual cycle phase, pain levels, and historical preferences.

### Key Features
- **Hierarchical Multi-Output Prediction**: Predicts TENS mode, TENS intensity level, and heat level simultaneously
- **Context-Aware Recommendations**: Considers menstrual cycle phase, pain levels, medication usage, time of day, and user experience
- **Intelligent Constraints**: Enforces physical device constraints (e.g., TENS level = 0 when mode = 0)
- **Real-Time API**: Serverless Cloud Function API with sub-second response times
- **High Accuracy**: 75-85% accuracy across all prediction tasks with comprehensive feature engineering

### Target Predictions
1. **TENS Mode** (4 classes: 0-3)
   - `0`: TENS therapy OFF
   - `1`: Low intensity continuous stimulation
   - `2`: Medium intensity burst stimulation
   - `3`: High intensity modulation stimulation

2. **TENS Level** (11 classes: 0-10)
   - Conditional on TENS mode: If mode = 0, level = 0
   - If mode > 0, predicts intensity level 1-10

3. **Heat Level** (4 classes: 0-3)
   - `0`: Heat OFF
   - `1`: Low heat
   - `2`: Medium heat
   - `3`: High heat

---

## 🏗️ Project Architecture

```
JunoAI/
├── tens_prediction_api/          # Production API (Cloud Function)
│   ├── main.py                   # API endpoint with hierarchical prediction logic
│   ├── requirements.txt          # Python dependencies
│   ├── deploy.sh                 # Deployment script
│   ├── .gcloudignore            # Files to exclude from deployment
│   └── README.md                # This file
│
├── Hierarchical_Classification_xgboost.ipynb   # Approach 2: LightGBM models
├── MultiOutput_DeepLearning.ipynb             # Approach 3: TensorFlow neural network
├── ML_Training_VertexAI.ipynb                 # Vertex AI training (BigQuery ML)
│
└── Scripts/
    ├── run-notebook.sh           # Jupyter notebook runner
    ├── open-jupyterlab.sh        # JupyterLab launcher
    └── update-ssh-ip.sh          # SSH configuration utility
```

### System Components

1. **Data Source**: BigQuery dataset (`junoplus-dev.junoplus_analytics.ml_training_data`)
   - 50,000+ therapy sessions
   - User demographics, cycle tracking, pain levels, device settings
   - Medication tracking, session outcomes

2. **ML Training Pipeline**: Three experimental approaches
   - Approach 1: BigQuery ML (Vertex AI AutoML)
   - Approach 2: Hierarchical LightGBM Classification
   - Approach 3: Multi-Output Deep Learning (TensorFlow/Keras)

3. **Production Models**: BigQuery ML models deployed on Vertex AI
   - `tens_mode_model`: Predicts TENS therapy mode
   - `tens_predictor_production_vertex`: Predicts TENS intensity level
   - `heat_predictor_production_vertex`: Predicts heat therapy level

4. **API Layer**: Google Cloud Function (Gen2)
   - Python 3.11 runtime
   - 512MB memory allocation
   - 60-second timeout
   - CORS-enabled HTTP endpoint

---

## 🧠 Machine Learning Approaches

The project explores three distinct ML approaches, each with different trade-offs for accuracy, interpretability, and deployment complexity.

### Approach 1: BigQuery ML with Vertex AI (Production)

**File**: `ML_Training_VertexAI.ipynb`

**Description**: Uses BigQuery ML's AutoML integration to train models directly in BigQuery, then exports to Vertex AI for production serving.

**Architecture**:
```sql
CREATE MODEL `tens_mode_model`
OPTIONS(model_type='BOOSTED_TREE_CLASSIFIER', ...)
AS SELECT features, target_tens_mode FROM training_data;
```

**Advantages**:
- ✅ Native BigQuery integration (no data export needed)
- ✅ Automatic hyperparameter tuning via AutoML
- ✅ Seamless Vertex AI deployment
- ✅ SQL-based training (accessible to data analysts)
- ✅ Built-in model versioning and monitoring

**Disadvantages**:
- ❌ Less control over model architecture
- ❌ Limited to BigQuery ML supported algorithms
- ❌ Higher training costs for large datasets

**Performance**: 
- TENS Mode: ~80% accuracy
- TENS Level: ~75% accuracy
- Heat Level: ~82% accuracy

---

### Approach 2: Hierarchical Classification with LightGBM

**File**: `Hierarchical_Classification_xgboost.ipynb`

**Description**: Two-stage hierarchical classification that enforces physical device constraints by first predicting TENS mode, then conditionally predicting intensity level.

**Architecture**:

**Stage 1: Base Predictions**
```python
# Train separate models for mode and heat
heat_model = LGBMClassifier(num_class=4, ...)
mode_model = LGBMClassifier(num_class=4, ...)

# Train on full dataset
heat_model.fit(X_train, y_heat)
mode_model.fit(X_train, y_mode)
```

**Stage 2: Conditional TENS Level**
```python
# Train TENS level model ONLY on sessions where mode > 0
active_sessions = data[data['tens_mode'] > 0]
tens_model = LGBMClassifier(num_class=11, ...)
tens_model.fit(X_active, y_tens_active)

# Prediction logic
if predicted_mode == 0:
    tens_level = 0
else:
    tens_level = tens_model.predict(features)
```

**Key Features**:
- **Feature Engineering**: 60+ features including:
  - Cycle context (days since period, cycle phase, ovulation)
  - Medication potency mapping and timing
  - User historical preferences (avg settings, mode values)
  - Adjustment deltas (final - initial settings)
  - Temporal features (hour, day of week, time category)
  - Pain effectiveness metrics

- **User-Stable Data Split**: 
  ```python
  # Ensures no user appears in multiple splits
  CASE 
    WHEN MOD(FARM_FINGERPRINT(userId), 10) < 7 THEN 'TRAIN'
    WHEN MOD(FARM_FINGERPRINT(userId), 10) < 9 THEN 'EVAL'
    ELSE 'TEST'
  END
  ```

- **Class Imbalance Handling**: Training Stage 2 only on active TENS sessions reduces irrelevant class 0 examples

**Advantages**:
- ✅ Enforces physical constraints (mode → level dependency)
- ✅ Higher accuracy on TENS level by focusing on relevant data
- ✅ Interpretable two-stage process
- ✅ Fast training with LightGBM (~5 minutes on 50K samples)
- ✅ Easy to inspect feature importance per stage

**Disadvantages**:
- ❌ Requires managing three separate models
- ❌ More complex deployment logic
- ❌ Stage 1 errors propagate to Stage 2

**Performance**:
- Heat Level: ~84% accuracy (4 classes)
- TENS Mode: ~81% accuracy (4 classes)
- TENS Level (Hierarchical): ~78% accuracy (11 classes)
- Weighted F1 Scores: 0.81-0.84 across all tasks

**Feature Importance** (Top 10):
1. `user_avg_tens` - User's historical average TENS level
2. `input_pain_level` - User-reported pain at session start
3. `days_since_period_start` - Menstrual cycle day
4. `user_mode_tens` - User's most frequently used TENS level
5. `period_pain_level` - Expected pain for this cycle phase
6. `has_pain_medication` - Currently taking pain meds
7. `recent_medication_usage` - Medication taken in last 6 hours
8. `session_hour` - Time of day (circadian effects)
9. `user_experience_level` - New vs experienced user
10. `delta_tens` - Previous adjustment behavior

---

### Approach 3: Multi-Output Deep Learning

**File**: `MultiOutput_DeepLearning.ipynb`

**Description**: Single unified neural network with shared feature extraction layers and task-specific output heads for simultaneous multi-target prediction.

**Architecture**:
```
Input Layer (60+ features)
    ↓
Dense(256) + ReLU + BatchNorm + Dropout(0.3)
    ↓
Dense(128) + ReLU + BatchNorm + Dropout(0.3)
    ↓
Dense(64) + ReLU + BatchNorm + Dropout(0.2)
    ↓
    ├─────────────┬─────────────┐
    ↓             ↓             ↓
Heat Head     Mode Head    Level Head
Dense(32)     Dense(32)    Dense(32)
    ↓             ↓             ↓
Dense(4)      Dense(4)     Dense(11)
Softmax       Softmax      Softmax
```

**Training Configuration**:
```python
model.compile(
    optimizer=Adam(lr=0.001),
    loss={
        'heat_output': 'categorical_crossentropy',
        'mode_output': 'categorical_crossentropy',
        'tens_output': 'categorical_crossentropy'
    },
    loss_weights={'heat': 1.0, 'mode': 1.0, 'tens': 1.0}
)

# Callbacks
EarlyStopping(patience=10, restore_best_weights=True)
ModelCheckpoint(save_best_only=True)
ReduceLROnPlateau(factor=0.5, patience=5)
```

**Key Features**:
- **Feature Scaling**: StandardScaler (mean=0, std=1) - critical for neural networks
- **One-Hot Encoding**: All categorical features and targets
- **Shared Representations**: Lower layers learn features useful for all tasks
- **Task-Specific Heads**: Final layers specialize for each prediction
- **Batch Normalization**: Stabilizes training and improves convergence
- **Dropout Regularization**: Prevents overfitting (0.2-0.3)

**Advantages**:
- ✅ Single model deployment (simpler pipeline)
- ✅ Shared feature learning (efficient parameter usage)
- ✅ Can capture inter-task dependencies
- ✅ End-to-end differentiable training
- ✅ Smooth probability distributions for confidence estimation

**Disadvantages**:
- ❌ Harder to interpret than tree-based models
- ❌ Requires careful hyperparameter tuning
- ❌ Longer training time (~20-30 minutes)
- ❌ Needs careful feature scaling and normalization
- ❌ Black box decision making

**Performance**:
- Heat Level: ~82% accuracy
- TENS Mode: ~79% accuracy  
- TENS Level: ~76% accuracy
- Average F1 Score: 0.79 (weighted)

**Model Size**: ~750K trainable parameters

---

## 📊 Data Pipeline & Feature Engineering

### Data Source: BigQuery Analytics Table

**Table**: `junoplus-dev.junoplus_analytics.ml_training_data`

**Schema** (key columns):
```sql
-- User Demographics
userId STRING
age INT64
cycle_length INT64
period_length INT64
days_since_signup INT64

-- Session Context  
sessionId STRING
therapyStartTime TIMESTAMP
session_hour INT64
day_of_week INT64
time_of_day_category STRING
therapyDuration FLOAT64

-- Cycle Tracking
cycle_day INT64
is_period_day BOOL
is_ovulation_day BOOL
cycle_phase_estimated STRING
period_pain_level INT64
flow_level INT64

-- Device Settings (Targets)
target_heat_level INT64      -- Most-used heat (0-3)
target_tens_mode INT64        -- Most-used TENS mode (0-3)
target_tens_level INT64       -- Most-used TENS level (0-10)
initial_heat_level INT64
initial_tens_mode INT64
initial_tens_level INT64
final_heat_level INT64
final_tens_mode INT64
final_tens_level INT64

-- Medication Context
has_pain_medication BOOL
medication_count INT64
active_medication_count INT64
recent_medication_usage FLOAT64
pain_medication_adherence FLOAT64

-- Pain & Effectiveness
input_pain_level INT64
pain_level_before INT64
pain_level_after INT64
pain_reduction INT64
pain_reduction_percentage FLOAT64
was_effective BOOL

-- Data Quality
session_quality STRING
user_made_adjustments BOOL
```

### Feature Engineering Pipeline

**1. Adjustment Delta Features**
```sql
-- Captures user adjustment behavior patterns
(final_heat_level - target_heat_level) AS delta_heat,
(final_tens_level - target_tens_level) AS delta_tens,
(final_tens_mode - target_tens_mode) AS delta_mode
```

**2. User Historical Preferences**
```sql
-- Aggregate user's historical stable preferences
SELECT 
    userId,
    AVG(target_heat_level) AS user_avg_heat,
    AVG(target_tens_level) AS user_avg_tens,
    APPROX_TOP_COUNT(target_heat_level, 1)[0].value AS user_mode_heat,
    APPROX_TOP_COUNT(target_tens_level, 1)[0].value AS user_mode_tens
FROM ml_training_data
GROUP BY userId
```

**3. Medication Potency Mapping**
```python
MEDICATION_POTENCY = {
    'Naproxen': 1.3,      # Strongest OTC
    'Advil': 1.15,
    'Ibuprofen': 1.1,
    'Voltaren': 1.05,
    'Midol': 1.0,         # Baseline
    'Paracetamol': 0.9,
    'Birth Control': 0.4,  # Hormonal
}
```

**4. Temporal Features**
```sql
-- Hour of day (circadian effects)
EXTRACT(HOUR FROM therapyStartTime) AS session_hour

-- Day of week (weekly patterns)
EXTRACT(DAYOFWEEK FROM therapyStartTime) AS day_of_week

-- Time category
CASE 
    WHEN session_hour BETWEEN 6 AND 11 THEN 'morning'
    WHEN session_hour BETWEEN 12 AND 17 THEN 'afternoon'
    WHEN session_hour BETWEEN 18 AND 21 THEN 'evening'
    ELSE 'night'
END AS time_of_day_category
```

**5. Cycle Phase Estimation**
```sql
CASE
    WHEN cycle_day BETWEEN 1 AND period_length THEN 'menstrual'
    WHEN cycle_day BETWEEN period_length+1 AND 14 THEN 'follicular'
    WHEN cycle_day BETWEEN 12 AND 16 THEN 'ovulation'
    ELSE 'luteal'
END AS cycle_phase_estimated
```

**6. User Experience Segmentation**
```sql
CASE
    WHEN days_since_signup < 30 THEN 'new_user'
    WHEN days_since_signup < 90 THEN 'learning_user'
    ELSE 'experienced_user'
END AS user_experience_level
```

### Data Quality Filters

```sql
WHERE target_heat_level IS NOT NULL
  AND target_tens_level IS NOT NULL
  AND target_tens_mode IS NOT NULL
  AND session_quality = 'high_quality'
  AND user_made_adjustments = TRUE
  AND therapyDuration >= 300  -- At least 5 minutes
```

**Rationale**: We only train on high-quality sessions where users actively adjusted settings, indicating genuine engagement and reliable preference data.

### Train/Eval/Test Split Strategy

**User-Stable Split** (prevents data leakage):
```sql
CASE 
    WHEN MOD(FARM_FINGERPRINT(userId), 10) < 7 THEN 'TRAIN'   -- 70%
    WHEN MOD(FARM_FINGERPRINT(userId), 10) < 9 THEN 'EVAL'    -- 20%
    ELSE 'TEST'                                                -- 10%
END AS data_split
```

**Why User-Stable?**
- Prevents same user appearing in train and test sets
- Evaluates model generalization to new users
- Realistic production performance estimation
- Deterministic (same split across re-runs)

**Split Distribution**:
- Training: ~35,000 sessions (1,200 users)
- Evaluation: ~10,000 sessions (350 users)
- Test: ~5,000 sessions (175 users)

---

## 🔌 API Architecture

### Cloud Function Implementation

**Runtime**: Python 3.11 (Gen2)  
**Memory**: 512MB  
**Timeout**: 60 seconds  
**Trigger**: HTTP POST  
**Authentication**: Unauthenticated (development) / API Key (production)

### Request Flow

```
Client Request
    ↓
[CORS Preflight Check]
    ↓
[Parameter Validation]
    ↓
[Feature Engineering]
    ↓
┌─────────────────────────────────┐
│   BigQuery ML Predictions       │
│                                 │
│ 1. Predict TENS Mode (model 1) │
│ 2. Predict TENS Level (model 2)│
│ 3. Predict Heat Level (model 3)│
└─────────────────────────────────┘
    ↓
[Hierarchical Logic Application]
    ↓
if predicted_mode == 0:
    tens_level = 0
else:
    tens_level = model_prediction
    ↓
[Confidence Scoring]
    ↓
[Explanation Generation]
    ↓
[JSON Response]
```

### Hierarchical Prediction Logic

```python
# Step 1: Predict TENS Mode (0-3)
mode_prediction = bq_query("""
    SELECT predicted_tens_mode
    FROM ML.PREDICT(MODEL `tens_mode_model`, ...)
""")

# Step 2: Predict TENS Level (0-10)
level_prediction = bq_query("""
    SELECT predicted_target_tens_level
    FROM ML.PREDICT(MODEL `tens_predictor_production_vertex`, ...)
""")

# Step 3: Predict Heat Level (0-3)
heat_prediction = bq_query("""
    SELECT predicted_target_heat_level
    FROM ML.PREDICT(MODEL `heat_predictor_production_vertex`, ...)
""")

# Step 4: Apply Hierarchical Constraint
if predicted_mode == 0:
    recommended_tens_level = 0  # TENS off
else:
    recommended_tens_level = round(max(1, min(10, level_prediction)))

recommended_heat_level = round(max(0, min(3, heat_prediction)))
```

---

## 🚀 Deployment Guide

### Prerequisites

1. **Google Cloud Project Setup**
   ```bash
   # Set your project
   gcloud config set project junoplus-dev
   
   # Enable required APIs
   gcloud services enable cloudfunctions.googleapis.com
   gcloud services enable bigquery.googleapis.com
   gcloud services enable aiplatform.googleapis.com
   ```

2. **Service Account Permissions**
   - BigQuery Data Viewer
   - BigQuery Job User
   - Vertex AI User

3. **Install Google Cloud SDK**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk
   
   # Authenticate
   gcloud auth login
   ```

### Deployment Steps

#### Automated Deployment

```bash
cd tens_prediction_api
chmod +x deploy.sh
./deploy.sh
```

### Post-Deployment Verification

```bash
# Get function details
gcloud functions describe predict-tens-level \
  --region us-central1 \
  --gen2

# View logs
gcloud functions logs read predict-tens-level \
  --region us-central1 \
  --limit 50
```

---

## 📡 API Usage & Integration

### Endpoint

```
POST https://us-central1-junoplus-dev.cloudfunctions.net/predict-tens-level
```

### Request Example

```bash
curl -X POST https://us-central1-junoplus-dev.cloudfunctions.net/predict-tens-level \
  -H 'Content-Type: application/json' \
  -d '{
    "user_age": 28,
    "user_cycle_length": 30,
    "user_period_length": 5,
    "is_period_day": true,
    "is_ovulation_day": false,
    "current_pain_level": 8,
    "current_flow_level": 4,
    "has_medications": true,
    "medication_count": 2,
    "user_experience": "experienced_user",
    "time_of_day": "afternoon",
    "previous_tens_level": 5,
    "tens_mode": "burst"
  }'
```

### Response Example

```json
{
  "recommended_tens_mode": 3,
  "recommended_tens_level": 8,
  "recommended_heat_level": 3,
  "confidence_score": 0.95,
  "recommendation_explanation": "High period pain detected - stronger therapy recommended",
  "additional_guidance": "Consider combining with heat therapy for enhanced relief",
  "context_used": {
    "is_period_day": true,
    "current_pain_level": 8,
    "predicted_mode": 3
  }
}
```

---

## 📈 Model Performance

### Hierarchical LightGBM (Approach 2)

| Metric | Heat Level | TENS Mode | TENS Level |
|--------|-----------|-----------|------------|
| **Accuracy** | 84.2% | 81.3% | 77.8% |
| **F1 Score** | 0.84 | 0.81 | 0.78 |

### Multi-Output Deep Learning (Approach 3)

| Metric | Heat Level | TENS Mode | TENS Level |
|--------|-----------|-----------|------------|
| **Accuracy** | 82.1% | 79.4% | 76.2% |
| **F1 Score** | 0.82 | 0.79 | 0.76 |

---

## 🧪 Development & Testing

### Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
functions-framework --target=predict_tens_level --debug

# Test
curl -X POST http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -d @test_payload.json
```

---

**Last Updated**: November 23, 2025  
**Version**: 2.0.0  
**Maintained by**: Juno Technologies AI Team
