-- Silver Layer: Enhanced Tables Based on ERD
-- Clean, processed, and enriched data ready for analytics

-- 1. SILVER_SLEEP_DATA - Sleep metrics from user health data
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_sleep_data`
PARTITION BY date
CLUSTER BY user_id
AS
WITH sleep_data AS (
  SELECT
    JSON_VALUE(data, '$.userId') as user_id,
    DATE(timestamp) as date,
    CAST(JSON_VALUE(data, '$.sleep_duration_mins') AS INT64) as sleep_duration_mins,
    CAST(JSON_VALUE(data, '$.sleep_quality_score') AS FLOAT64) as sleep_quality_score,
    CAST(JSON_VALUE(data, '$.deep_sleep_mins') AS INT64) as deep_sleep_mins,
    CAST(JSON_VALUE(data, '$.light_sleep_mins') AS INT64) as light_sleep_mins,
    CAST(JSON_VALUE(data, '$.awake_mins') AS INT64) as awake_mins,
    TIMESTAMP(JSON_VALUE(data, '$.bedtime')) as bedtime,
    TIMESTAMP(JSON_VALUE(data, '$.wake_time')) as wake_time,
    ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(data, '$.userId'), DATE(timestamp) ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.user_health_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
    AND JSON_VALUE(data, '$.sleep_duration_mins') IS NOT NULL
)
SELECT
  user_id,
  date,
  sleep_duration_mins,
  sleep_quality_score,
  deep_sleep_mins,
  light_sleep_mins,
  awake_mins,
  bedtime,
  wake_time,
  -- Derived metrics
  CASE 
    WHEN sleep_duration_mins >= 420 THEN 'Adequate' -- 7+ hours
    WHEN sleep_duration_mins >= 360 THEN 'Moderate' -- 6-7 hours
    ELSE 'Insufficient' -- < 6 hours
  END as sleep_category,
  SAFE_DIVIDE(deep_sleep_mins, sleep_duration_mins) as deep_sleep_ratio,
  CURRENT_TIMESTAMP() as processed_at
FROM sleep_data
WHERE rn = 1;

-- 2. SILVER_PERIOD_TRACKING - Period tracking data
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_period_tracking`
PARTITION BY date
CLUSTER BY user_id
AS
WITH period_data AS (
  SELECT
    JSON_VALUE(data, '$.userId') as user_id,
    DATE(TIMESTAMP(JSON_VALUE(data, '$.date'))) as date,
    CAST(JSON_VALUE(data, '$.cycle_day') AS INT64) as cycle_day,
    JSON_VALUE(data, '$.flow_intensity') as flow_intensity,
    JSON_VALUE(data, '$.symptoms') as symptoms,
    JSON_VALUE(data, '$.mood') as mood,
    JSON_VALUE(data, '$.notes') as notes,
    CAST(JSON_VALUE(data, '$.pain_level') AS INT64) as pain_level,
    ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(data, '$.userId'), DATE(TIMESTAMP(JSON_VALUE(data, '$.date'))) ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.period_tracking_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
)
SELECT
  user_id,
  date,
  cycle_day,
  flow_intensity,
  symptoms,
  mood,
  notes,
  pain_level,
  -- Derived fields
  CASE 
    WHEN cycle_day BETWEEN 1 AND 5 THEN 'Menstrual'
    WHEN cycle_day BETWEEN 6 AND 13 THEN 'Follicular'
    WHEN cycle_day BETWEEN 14 AND 16 THEN 'Ovulation'
    WHEN cycle_day BETWEEN 17 AND 28 THEN 'Luteal'
    ELSE 'Unknown'
  END as cycle_phase,
  CASE WHEN pain_level >= 7 THEN TRUE ELSE FALSE END as high_pain_day,
  CURRENT_TIMESTAMP() as processed_at
FROM period_data
WHERE rn = 1;

-- 3. SILVER_THERAPY_SESSIONS - Enhanced therapy sessions
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
PARTITION BY session_date
CLUSTER BY user_id
AS
WITH session_data AS (
  SELECT
    document_id as session_id,
    JSON_VALUE(path_params, '$.userId') as user_id,
    JSON_VALUE(data, '$.deviceInformation.deviceId') as device_id,
    JSON_VALUE(data, '$.deviceInformation.deviceName') as device_name,
    DATE(TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64))) as session_date,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64)) as start_time,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyEndTime._seconds') AS INT64)) as end_time,
    CAST(JSON_VALUE(data, '$.sessionInfo.therapyDuration') AS INT64) as duration_minutes,
    JSON_VALUE(data, '$.status') as status,
    -- Settings
    CAST(JSON_VALUE(data, '$.initialSettings.heatLevel') AS INT64) as initial_heat,
    CAST(JSON_VALUE(data, '$.initialSettings.tensMode') AS INT64) as initial_mode,
    CAST(JSON_VALUE(data, '$.initialSettings.tensLevel') AS INT64) as initial_tens,
    CAST(JSON_VALUE(data, '$.finalSettings.heatLevel') AS INT64) as final_heat,
    CAST(JSON_VALUE(data, '$.finalSettings.tensMode') AS INT64) as final_mode,
    CAST(JSON_VALUE(data, '$.finalSettings.tensLevel') AS INT64) as final_tens,
    -- Feedback
    CAST(JSON_VALUE(data, '$.feedback.painLevelBefore') AS INT64) as pain_before,
    CAST(JSON_VALUE(data, '$.feedback.painLevelAfter') AS INT64) as pain_after,
    CAST(JSON_VALUE(data, '$.feedback.feedbackCompleted') AS BOOL) as has_feedback,
    ROW_NUMBER() OVER (PARTITION BY document_id ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.therapy_sessions_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
)
SELECT
  session_id,
  user_id,
  device_id,
  device_name,
  session_date,
  start_time,
  end_time,
  duration_minutes,
  status,
  initial_heat,
  initial_mode,
  initial_tens,
  final_heat,
  final_mode,
  final_tens,
  pain_before,
  pain_after,
  has_feedback,
  -- Effectiveness metrics
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
  -- Adjustment tracking
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

-- 4. SILVER_MEDICATIONS - Medication tracking
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
  -- Derived fields
  CURRENT_TIMESTAMP() as processed_at
FROM flat_meds
WHERE rn = 1;

-- 5. SILVER_USER_HEALTH_DATA - Comprehensive user health metrics
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_user_health_data`
PARTITION BY date
CLUSTER BY user_id
AS
WITH health_data AS (
  SELECT
    JSON_VALUE(data, '$.userId') as user_id,
    DATE(timestamp) as date,
    CAST(JSON_VALUE(data, '$.weight_kg') AS FLOAT64) as weight_kg,
    CAST(JSON_VALUE(data, '$.height_cm') AS FLOAT64) as height_cm,
    CAST(JSON_VALUE(data, '$.bmi') AS FLOAT64) as bmi,
    CAST(JSON_VALUE(data, '$.heart_rate_avg') AS INT64) as heart_rate_avg,
    CAST(JSON_VALUE(data, '$.steps_count') AS INT64) as steps_count,
    CAST(JSON_VALUE(data, '$.calories_burned') AS INT64) as calories_burned,
    CAST(JSON_VALUE(data, '$.water_intake_ml') AS INT64) as water_intake_ml,
    CAST(JSON_VALUE(data, '$.stress_level') AS INT64) as stress_level,
    ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(data, '$.userId'), DATE(timestamp) ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.user_health_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
)
SELECT
  user_id,
  date,
  weight_kg,
  height_cm,
  bmi,
  heart_rate_avg,
  steps_count,
  calories_burned,
  water_intake_ml,
  stress_level,
  -- Activity levels
  CASE 
    WHEN steps_count >= 10000 THEN 'Very Active'
    WHEN steps_count >= 7000 THEN 'Active'
    WHEN steps_count >= 5000 THEN 'Moderate'
    ELSE 'Sedentary'
  END as activity_level,
  -- BMI category
  CASE 
    WHEN bmi < 18.5 THEN 'Underweight'
    WHEN bmi < 25 THEN 'Normal'
    WHEN bmi < 30 THEN 'Overweight'
    ELSE 'Obese'
  END as bmi_category,
  CURRENT_TIMESTAMP() as processed_at
FROM health_data
WHERE rn = 1;
