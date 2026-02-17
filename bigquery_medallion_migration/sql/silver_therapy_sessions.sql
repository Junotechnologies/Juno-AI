-- Silver Layer: Therapy Sessions
-- Source: therapy_sessions_data_raw_changelog (Sub-collection)
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
PARTITION BY session_date
CLUSTER BY user_id
AS
WITH session_data AS (
  SELECT
    document_id as session_id,
    JSON_VALUE(path_params, '$.userId') as user_id,
    JSON_VALUE(data, '$.deviceInformation.deviceName') as device_name,
    DATE(TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64))) as session_date,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64)) as start_time,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyEndTime._seconds') AS INT64)) as end_time,
    CAST(JSON_VALUE(data, '$.sessionInfo.therapyDuration') AS INT64) as duration_minutes,
    JSON_VALUE(data, '$.status') as status,
    CAST(JSON_VALUE(data, '$.initialSettings.heatLevel') AS INT64) as initial_heat,
    CAST(JSON_VALUE(data, '$.initialSettings.tensMode') AS INT64) as initial_mode,
    CAST(JSON_VALUE(data, '$.initialSettings.tensLevel') AS INT64) as initial_tens,
    CAST(JSON_VALUE(data, '$.finalSettings.heatLevel') AS INT64) as final_heat,
    CAST(JSON_VALUE(data, '$.finalSettings.tensMode') AS INT64) as final_mode,
    CAST(JSON_VALUE(data, '$.finalSettings.tensLevel') AS INT64) as final_tens,
    CAST(JSON_VALUE(data, '$.feedback.painLevelBefore') AS INT64) as pain_before,
    CAST(JSON_VALUE(data, '$.feedback.painLevelAfter') AS INT64) as pain_after,
    CAST(JSON_VALUE(data, '$.feedback.feedbackCompleted') AS BOOL) as has_feedback,
    ROW_NUMBER() OVER (PARTITION BY document_id ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.therapy_sessions_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
)
SELECT
  * EXCEPT(rn),
  CASE 
    WHEN pain_before IS NOT NULL AND pain_after IS NOT NULL 
    THEN pain_before - pain_after 
    ELSE NULL 
  END as pain_reduction,
  CASE 
    WHEN pain_before IS NOT NULL AND pain_after IS NOT NULL AND pain_before > 0
    THEN SAFE_DIVIDE(pain_before - pain_after, pain_before)
    ELSE NULL 
  END as pain_reduction_pct,
  CASE 
    WHEN pain_before IS NOT NULL AND pain_after IS NOT NULL 
      AND (pain_before - pain_after) >= 2 
    THEN TRUE 
    ELSE FALSE 
  END as was_effective,
  CASE 
    WHEN final_heat != initial_heat 
      OR final_tens != initial_tens 
      OR final_mode != initial_mode 
    THEN TRUE 
    ELSE FALSE 
  END as user_adjusted,
  CURRENT_TIMESTAMP() as processed_at
FROM session_data
WHERE rn = 1;
