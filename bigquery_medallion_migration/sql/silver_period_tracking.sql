-- Silver Layer: Period Tracking
-- Source: period_tracking_data_raw_latest (View)
-- Uses the latest snapshot view from Firestore Sync
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_period_tracking`
CLUSTER BY user_id
AS
SELECT
  JSON_VALUE(path_params, '$.userId') as user_id,
  document_id as cycle_id,
  -- These will be NULL for now as the current raw schema is complex to flatten
  CAST(NULL AS DATE) as date,
  CAST(NULL AS INT64) as cycle_day,
  CAST(NULL AS STRING) as flow_intensity,
  CAST(NULL AS STRING) as symptoms,
  CAST(NULL AS INT64) as pain_level,
  CAST(NULL AS BOOL) as high_pain_day,
  CAST(NULL AS STRING) as cycle_phase,
  JSON_VALUE(data, '$.status') as cycle_status,
  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.lastUpdate._seconds') AS INT64)) as last_update,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics.period_tracking_data_raw_latest`
WHERE data IS NOT NULL;
