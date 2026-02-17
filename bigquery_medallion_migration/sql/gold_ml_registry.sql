-- ML Registry Tables for tracking models, experiments, and datasets

-- DATASET_SNAPSHOTS - Records of data exports used for training
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.dataset_snapshots`
PARTITION BY snapshot_date
CLUSTER BY dataset_id
AS
SELECT
  GENERATE_UUID() as snapshot_id,
  'ml_training_base' as dataset_id,
  CURRENT_DATE() as snapshot_date,
  COUNT(*) as row_count,
  'junoplus-dev.junoplus_analytics_gold.ml_training_base' as source_table,
  'Initial snapshot from ML training base table' as description,
  CURRENT_TIMESTAMP() as created_at
FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`;

-- DATASET_REGISTRY - Metadata for training datasets
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.dataset_registry`
CLUSTER BY dataset_id
AS
SELECT
  'ml_training_v1' as dataset_id,
  'ML Training Dataset v1' as dataset_name,
  'Training data with therapy sessions, user health, period tracking' as description,
  DATE('2024-01-01') as data_start_date,
  CURRENT_DATE() as data_end_date,
  ARRAY['pain_before', 'pain_after', 'initial_heat', 'initial_mode', 'initial_tens', 
        'cycle_day', 'cycle_phase', 'bmi', 'heart_rate_avg', 'sleep_quality_score'] as feature_list,
  ARRAY['pain_reduction', 'pain_reduction_pct', 'was_effective'] as label_list,
  'junoplus-dev.junoplus_analytics_gold.ml_training_data_v1' as source_table,
  'active' as status,
  CURRENT_TIMESTAMP() as created_at,
  CURRENT_TIMESTAMP() as updated_at;

-- MODEL_REGISTRY - Tracks deployed models
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.model_registry`
CLUSTER BY model_id
AS
SELECT
  'model_v1_initial' as model_id,
  'Pain Prediction Model v1' as model_name,
  'XGBoost' as model_type,
  'Initial baseline model for pain reduction prediction' as description,
  'gs://junoplus-models/pain-prediction-v1' as model_uri,
  NULL as vertex_ai_endpoint,
  STRUCT(
    0.75 as accuracy,
    0.72 as precision,
    0.78 as recall,
    0.75 as f1_score,
    0.82 as auc
  ) as evaluation_metrics,
  'ml_training_v1' as training_dataset_id,
  'pending' as deployment_status,
  CURRENT_TIMESTAMP() as created_at,
  CURRENT_TIMESTAMP() as last_updated;

-- EXPERIMENT_REGISTRY - Records experiment results
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.experiment_registry`
PARTITION BY experiment_date
CLUSTER BY experiment_id
AS
SELECT
  'exp_001' as experiment_id,
  'Baseline Model Comparison' as experiment_name,
  'Compare XGBoost vs Random Forest for pain prediction' as objective,
  CURRENT_DATE() as experiment_date,
  ARRAY['model_v1_xgboost', 'model_v1_rf'] as models_compared,
  'model_v1_xgboost' as winner_model_id,
  STRUCT(
    'XGBoost showed 5% better accuracy and faster inference time' as rationale,
    'Deploy XGBoost as primary model' as decision,
    'user_researcher' as decided_by
  ) as human_decision,
  STRUCT(
    0.75 as winning_accuracy,
    0.70 as runner_up_accuracy,
    250 as training_time_minutes,
    'balanced' as data_split_strategy
  ) as experiment_metadata,
  CURRENT_TIMESTAMP() as created_at;
