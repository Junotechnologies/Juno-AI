# Hierarchical XGBoost Classification Approach

## 📋 Overview

This approach uses a hierarchical classification strategy with LightGBM (XGBoost-compatible) to predict device settings for JunoPlus therapy sessions. The model predicts three outputs independently with a hierarchical constraint on TENS Level.

## 🎯 What This Approach Predicts

1. **Heat Level** (0-3): Heating pad intensity
2. **TENS Mode** (0-3): TENS therapy mode (0=off, 1-3=intensity levels)
3. **TENS Level** (0-10): TENS therapy level (only predicted when Mode > 0)

## 🏗️ Architecture

### Two-Stage Hierarchical Prediction
```
Stage 1 (Independent):
├── Heat Level Model (4 classes)
└── TENS Mode Model (4 classes)

Stage 2 (Conditional):
└── TENS Level Model (11 classes)
    └── Only runs if Mode > 0
    └── Returns 0 if Mode = 0
```

## 🚀 Current Performance (Version 2.0)

| Output | Accuracy | F1 Score |
|--------|----------|----------|
| Heat Level | **100.0%** | **100.0%** |
| TENS Mode | 59.2% | 59.1% |
| TENS Level | **67.1%** | **68.4%** |

## 📂 Files

- `hierarchical_classification_xgboost.ipynb` - Main training notebook
- `IMPROVEMENTS_REPORT.md` - Detailed version history and improvements
- `models/hierarchical_approach/` - Saved model artifacts
  - `heat_level_model.pkl` - Heat level classifier
  - `tens_mode_model.pkl` - TENS mode classifier
  - `tens_level_model.pkl` - TENS level regressor
  - `feature_columns.pkl` - Feature names for inference

## 🔑 Key Features

### Enhanced Feature Engineering
- User historical preferences (rolling averages)
- Cycle context (period day, cycle phase)
- Pain-medication interactions
- Temporal patterns (time of day, weekend)

### Advanced Techniques
- Class balancing for imbalanced data
- 5-fold cross-validation
- Confidence-based hierarchical prediction
- Early stopping to prevent overfitting

## 💡 Advantages

✅ **Perfect Heat Level Prediction** - 100% accuracy  
✅ **High Interpretability** - Feature importance easily understood  
✅ **Fast Inference** - Millisecond predictions  
✅ **Production-Ready** - Standard pickle format  
✅ **Hierarchical Logic** - Respects Mode=0 constraint  

## ⚠️ Limitations

- TENS Mode accuracy needs improvement (59.2%)
- Requires separate models for each output
- Less effective at capturing inter-dependencies between settings
- 43% of TENS Level predictions use fallback mechanism

## 🎓 When to Use This Approach

**Best for:**
- Scenarios requiring interpretable predictions
- When feature importance analysis is critical
- Fast inference requirements
- Traditional ML pipeline deployment

**Not ideal for:**
- Capturing complex inter-task relationships
- When unified model architecture is preferred
- Learning shared representations across tasks

## 📊 Training Data

- **Total Sessions**: 27,995 high-quality sessions
- **Training**: 24,095 sessions (86.1%) from 280 users
- **Evaluation**: 2,668 sessions (9.5%) from 32 users
- **Test**: 1,232 sessions (4.4%) from 14 users
- **User-Stable Split**: ✅ No user overlap between sets

## 🔧 Usage

```python
import pickle
import pandas as pd

# Load models
with open('models/hierarchical_approach/heat_level_model.pkl', 'rb') as f:
    heat_model = pickle.load(f)
with open('models/hierarchical_approach/tens_mode_model.pkl', 'rb') as f:
    mode_model = pickle.load(f)
with open('models/hierarchical_approach/tens_level_model.pkl', 'rb') as f:
    level_model = pickle.load(f)

# Load feature columns
with open('models/hierarchical_approach/feature_columns.pkl', 'rb') as f:
    feature_cols = pickle.load(f)

# Prepare input
input_features = df[feature_cols]

# Stage 1: Predict Heat and Mode
heat_pred = heat_model.predict(input_features)
mode_pred = mode_model.predict(input_features)
mode_proba = mode_model.predict_proba(input_features)

# Stage 2: Predict Level (hierarchical)
level_pred = np.zeros(len(input_features))
active_mask = mode_pred > 0
confidence_mask = mode_proba.max(axis=1) > 0.5

if active_mask.sum() > 0:
    high_conf_mask = active_mask & confidence_mask
    if high_conf_mask.sum() > 0:
        level_pred[high_conf_mask] = level_model.predict(input_features[high_conf_mask])
    
    low_conf_mask = active_mask & ~confidence_mask
    if low_conf_mask.sum() > 0:
        level_pred[low_conf_mask] = 4  # Fallback level
```

## 📈 Next Steps

See `IMPROVEMENTS_REPORT.md` for:
- Future optimization plans
- Hyperparameter tuning roadmap
- Ensemble method strategies
- Deep learning integration ideas
