-- Bronze Layer: Raw Tables from ERD
-- These tables extract specific data from the raw changelog tables
-- Note: The main *_raw_changelog tables are managed by Firebase Extension

-- 1. RAW_SESSIONS - Core session data (one per session)
CREATE OR REPLACE VIEW `junoplus-dev.junoplus_analytics.raw_sessions`
AS
SELECT
  document_id as session_id,
  JSON_VALUE(path_params, '$.userId') as user_id,
  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64)) as start_timestamp,
  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyEndTime._seconds') AS INT64)) as end_timestamp,
  JSON_VALUE(data, '$.deviceInformation.deviceId') as device_id,
  JSON_VALUE(data, '$.deviceInformation.deviceName') as device_name,
  JSON_VALUE(data, '$.deviceInformation.deviceType') as device_type,
  JSON_VALUE(data, '$.status') as status,
  CAST(JSON_VALUE(data, '$.sessionInfo.therapyDuration') AS INT64) as duration_minutes,
  -- Prediction/Context
  JSON_VALUE(data, '$.cycle_phase_estimated') as cycle_phase,
  CAST(JSON_VALUE(data, '$.is_near_period') AS BOOL) as is_near_period,
  timestamp as sync_timestamp,
  operation
FROM `junoplus-dev.junoplus_analytics.therapy_sessions_data_raw_changelog`
WHERE operation IN ('CREATE', 'UPDATE')
  AND data IS NOT NULL;

-- 2. RAW_RECOMMENDATIONS - Settings recommended by AI
CREATE OR REPLACE VIEW `junoplus-dev.junoplus_analytics.raw_recommendations`
AS
SELECT
  document_id as session_id,
  JSON_VALUE(path_params, '$.userId') as user_id,
  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.initialSettings.timestamp._seconds') AS INT64)) as recommendation_timestamp,
  CAST(JSON_VALUE(data, '$.initialSettings.heatLevel') AS INT64) as recommended_heat,
  CAST(JSON_VALUE(data, '$.initialSettings.tensMode') AS INT64) as recommended_mode,
  CAST(JSON_VALUE(data, '$.initialSettings.tensLevel') AS INT64) as recommended_level,
  timestamp as sync_timestamp
FROM `junoplus-dev.junoplus_analytics.therapy_sessions_data_raw_changelog`
WHERE operation IN ('CREATE', 'UPDATE')
  AND data IS NOT NULL
  AND JSON_VALUE(data, '$.initialSettings.heatLevel') IS NOT NULL;

-- 3. RAW_USER_ADJUSTMENTS - User overrides during session
CREATE OR REPLACE VIEW `junoplus-dev.junoplus_analytics.raw_user_adjustments`
AS
SELECT
  document_id as session_id,
  JSON_VALUE(path_params, '$.userId') as user_id,
  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.finalSettings.timestamp._seconds') AS INT64)) as adjustment_timestamp,
  -- Initial
  CAST(JSON_VALUE(data, '$.initialSettings.heatLevel') AS INT64) as initial_heat,
  CAST(JSON_VALUE(data, '$.initialSettings.tensMode') AS INT64) as initial_mode,
  CAST(JSON_VALUE(data, '$.initialSettings.tensLevel') AS INT64) as initial_level,
  -- Final
  CAST(JSON_VALUE(data, '$.finalSettings.heatLevel') AS INT64) as final_heat,
  CAST(JSON_VALUE(data, '$.finalSettings.tensMode') AS INT64) as final_mode,
  CAST(JSON_VALUE(data, '$.finalSettings.tensLevel') AS INT64) as final_tens,
  timestamp as sync_timestamp
FROM `junoplus-dev.junoplus_analytics.therapy_sessions_data_raw_changelog`
WHERE operation IN ('CREATE', 'UPDATE')
  AND data IS NOT NULL
  AND JSON_VALUE(data, '$.finalSettings.timestamp') IS NOT NULL;

-- 4. RAW_FEEDBACK - User-reported pain levels
CREATE OR REPLACE VIEW `junoplus-dev.junoplus_analytics.raw_feedback`
AS
SELECT
  document_id as session_id,
  JSON_VALUE(path_params, '$.userId') as user_id,
  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.feedback.feedbackSubmittedAt._seconds') AS INT64)) as feedback_timestamp,
  CAST(JSON_VALUE(data, '$.feedback.painLevelBefore') AS INT64) as pain_before,
  CAST(JSON_VALUE(data, '$.feedback.painLevelAfter') AS INT64) as pain_after,
  timestamp as sync_timestamp
FROM `junoplus-dev.junoplus_analytics.therapy_sessions_data_raw_changelog`
WHERE operation IN ('CREATE', 'UPDATE')
  AND data IS NOT NULL
  AND JSON_VALUE(data, '$.feedback.feedbackSubmittedAt') IS NOT NULL;
