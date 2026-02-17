-- Silver Layer: Medications
-- Source: medications_data_raw_changelog
-- Logic: Flattens the medications array found in user documents
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_medications`
CLUSTER BY user_id
AS
WITH med_array AS (
  SELECT
    document_id as user_id,
    JSON_EXTRACT_ARRAY(data, '$.medications') as meds,
    timestamp
  FROM `junoplus-dev.junoplus_analytics.medications_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
),
flat_meds AS (
  SELECT
    user_id,
    JSON_VALUE(med, '$.name') as medication_name,
    JSON_VALUE(med, '$.dosage') as dosage,
    JSON_VALUE(med, '$.frequency') as frequency,
    JSON_VALUE(med, '$.frequencyUnit') as frequency_unit,
    DATE(TIMESTAMP(JSON_VALUE(med, '$.startDate'))) as start_date,
    CAST(JSON_VALUE(med, '$.isNotificationEnabled') AS BOOL) as notifications_enabled,
    ROW_NUMBER() OVER (PARTITION BY user_id, JSON_VALUE(med, '$.name') ORDER BY timestamp DESC) as rn
  FROM med_array,
  UNNEST(meds) as med
)
SELECT
  user_id,
  medication_name,
  dosage,
  frequency,
  frequency_unit,
  start_date,
  notifications_enabled,
  'Active' as medication_status,
  'Unknown' as adherence_category,
  CURRENT_TIMESTAMP() as processed_at
FROM flat_meds
WHERE rn = 1;
