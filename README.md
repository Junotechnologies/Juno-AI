# JunoAI - ML Model Training Repository

## 📋 Project Overview

This repository contains three distinct machine learning approaches for predicting optimal device settings (Heat Level, TENS Mode, TENS Level) for JunoPlus therapy sessions. Each approach has been organized into its own folder with complete documentation and monthly improvement tracking.

## 📁 Repository Structure

```
JunoAI/
├── hierarchical_xgboost_approach/
│   ├── hierarchical_classification_xgboost.ipynb
│   ├── IMPROVEMENTS_REPORT.md
│   ├── README.md
│   └── models/
│       └── hierarchical_approach/
├── vertex_ai_training_approach/
│   ├── vertex_ai_ml_training.ipynb
│   ├── IMPROVEMENTS_REPORT.md
│   └── README.md
├── multioutput_deeplearning_approach/
│   ├── multioutput_deeplearning_model.ipynb
│   ├── IMPROVEMENTS_REPORT.md
│   ├── README.md
│   └── models/
│       └── multioutput_approach/
├── models/
│   └── (shared model artifacts)
├── tens_prediction_api/
│   └── (API deployment files)
└── README.md (this file)
```

## 🎯 Approach Comparison

| Approach | Heat | Mode | Level | Avg | Training Time | Deployment |
|----------|------|------|-------|-----|--------------|------------|
| **XGBoost Hierarchical** | 🥇 **100%** | 59.2% | 67.1% | 75.4% | ~5 min | Easy |
| **Vertex AI BigQuery ML** | N/A | N/A | MAE: 1.18 | - | ~2 min | Cloud-Only |
| **Deep Learning Multi-Output** | 98.2% | 🥇 **94.5%** | 🥇 **72.8%** | 🥇 **88.5%** | ~12 min | Medium |

### 🏆 Winner by Category

- **Best Heat Level**: XGBoost (100% accuracy)
- **Best TENS Mode**: Deep Learning (94.5% accuracy)
- **Best TENS Level**: Deep Learning (72.8% accuracy)
- **Best Overall**: Deep Learning (88.5% average accuracy)
- **Best Interpretability**: XGBoost (feature importance)
- **Best Scalability**: Vertex AI (serverless, BigQuery integration)
- **Fastest Training**: Vertex AI (~2 minutes)
- **Fastest Inference**: XGBoost (<10ms per prediction)

## 📊 Detailed Approach Breakdowns

### 1. Hierarchical XGBoost Classification

**Best for**: Interpretability, fast inference, perfect heat level prediction

**Architecture**: Two-stage hierarchical prediction
- Stage 1: Independent Heat and Mode classifiers
- Stage 2: Conditional TENS Level prediction (only when Mode > 0)

**Key Features**:
- ✅ Perfect 100% Heat Level accuracy
- ✅ High feature importance interpretability
- ✅ Sub-millisecond inference time
- ✅ Standard pickle format (easy deployment)
- ⚠️ TENS Mode needs improvement (59.2%)

**See**: `hierarchical_xgboost_approach/README.md` for details

---

### 2. Vertex AI ML Training

**Best for**: Cloud-native deployment, BigQuery integration, scalability

**Architecture**: BigQuery ML BOOSTED_TREE_REGRESSOR
- Direct training on BigQuery data
- Vertex AI experiment tracking
- SQL-based inference via TABLE FUNCTION

**Key Features**:
- ✅ Serverless training and inference
- ✅ Native BigQuery integration (no data movement)
- ✅ Automated experiment tracking
- ✅ Scalable to millions of predictions/day
- ⚠️ Primarily single-output (TENS Level focus)

**See**: `vertex_ai_training_approach/README.md` for details

---

### 3. Multi-Output Deep Learning

**Best for**: Overall accuracy, unified predictions, capturing inter-dependencies

**Architecture**: Shared neural network with task-specific heads
- 3-layer shared base (256 → 128 → 64)
- 3 independent output heads (Heat, Mode, Level)
- Multi-task learning with batch normalization

**Key Features**:
- ✅ Highest average accuracy (88.5%)
- ✅ Best TENS Mode (94.5%) and Level (72.8%)
- ✅ Single unified model
- ✅ Captures inter-task relationships
- ⚠️ Slightly lower Heat accuracy vs XGBoost (98.2% vs 100%)

**See**: `multioutput_deeplearning_approach/README.md` for details

---

## 📈 Monthly Improvement Tracking

Each approach folder contains an `IMPROVEMENTS_REPORT.md` file with:
- **Monthly changelog** (grouped by year-month)
- **Performance metrics** before and after changes
- **Detailed analysis** of what worked and what didn't
- **Lessons learned** from each iteration
- **Future optimization ideas** prioritized

### Report Format

```markdown
# [Approach Name] - Monthly Improvements Report

## 📅 December 2024

### Version X.X - [Change Description] (Date)

**Summary**: Brief overview

#### Changes Implemented
- Detailed changes

#### Performance Results
- Metrics and comparisons

#### Key Insights
- Lessons learned
```

## 🚀 Quick Start

### 1. Choose Your Approach

**Need maximum interpretability?** → Use XGBoost Hierarchical  
**Deploying on Google Cloud?** → Use Vertex AI  
**Want best overall accuracy?** → Use Multi-Output Deep Learning  

### 2. Open the Notebook

```bash
# Navigate to the approach folder
cd [approach_folder_name]

# Open Jupyter notebook
jupyter notebook [notebook_name].ipynb
```

### 3. Review Improvements

```bash
# Read the improvements report
cat IMPROVEMENTS_REPORT.md
```

## 🔧 Requirements

### All Approaches
- Python 3.8+
- pandas
- numpy
- scikit-learn

### XGBoost Approach
- lightgbm
- matplotlib
- seaborn

### Vertex AI Approach
- google-cloud-bigquery
- google-cloud-aiplatform

### Deep Learning Approach
- tensorflow 2.x
- keras
- matplotlib
- plotly

## 📚 Documentation

Each approach folder contains:
1. **README.md** - Overview, architecture, usage examples
2. **IMPROVEMENTS_REPORT.md** - Monthly changelog with performance tracking
3. **Jupyter Notebook** - Complete training pipeline
4. **Models folder** - Saved artifacts

## 🎯 Recommendation Matrix

| Use Case | Recommended Approach | Reason |
|----------|---------------------|--------|
| Production deployment (accuracy priority) | Deep Learning | Best overall performance (88.5%) |
| Production deployment (speed priority) | XGBoost | Fastest inference (<10ms) |
| Cloud-native architecture | Vertex AI | Serverless, scalable, BigQuery native |
| Research & experimentation | All three | Compare and ensemble |
| Interpretability required | XGBoost | Feature importance analysis |
| Consistent multi-output predictions | Deep Learning | Unified architecture |

## 🏗️ Ensemble Strategy (Recommended)

For maximum reliability, consider an ensemble approach:

1. **Heat Level**: Use XGBoost (100% accuracy)
2. **TENS Mode**: Use Deep Learning (94.5% accuracy)
3. **TENS Level**: Ensemble average of Deep Learning + XGBoost

This hybrid strategy leverages the strengths of each approach.

## 📞 Contact & Contributions

For questions, improvements, or contributions, please:
1. Review the appropriate approach folder
2. Check the IMPROVEMENTS_REPORT.md for context
3. Follow the established monthly tracking format

---

**Last Updated**: December 5, 2024  
**Repository Status**: ✅ Active Development  
**Latest Version**: All approaches at v2.0 or v1.0
