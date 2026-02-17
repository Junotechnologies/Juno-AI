-- Gold Layer: Analytics & Reporting Tables from ERD
-- Business-level aggregations and dimension/fact tables

-- 1. GOLD_SLEEP_ANALYTICS - Sleep pattern analysis
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.gold_sleep_analytics`
PARTITION BY month
CLUSTER BY user_id
AS
SELECT
  user_id,
  DATE_TRUNC(date, MONTH) as month,
  -- Sleep metrics
  AVG(sleep_duration_mins) as avg_sleep_duration_mins,
  AVG(sleep_quality_score) as avg_sleep_quality_score,
  AVG(deep_sleep_mins) as avg_deep_sleep_mins,
  AVG(light_sleep_mins) as avg_light_sleep_mins,
  AVG(awake_mins) as avg_awake_mins,
  AVG(deep_sleep_ratio) as avg_deep_sleep_ratio,
  -- Quality metrics
  STDDEV(sleep_duration_mins) as sleep_consistency,
  COUNT(*) as nights_tracked,
  COUNTIF(sleep_category = 'Adequate') as adequate_sleep_nights,
  COUNTIF(sleep_category = 'Insufficient') as poor_sleep_nights,
  -- Consistency score (lower is better)
  CASE 
    WHEN STDDEV(sleep_duration_mins) < 30 THEN 'Very Consistent'
    WHEN STDDEV(sleep_duration_mins) < 60 THEN 'Consistent'
    WHEN STDDEV(sleep_duration_mins) < 90 THEN 'Moderate'
    ELSE 'Inconsistent'
  END as consistency_category,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_sleep_data`
GROUP BY user_id, DATE_TRUNC(date, MONTH);

-- 2. GOLD_THERAPY_EFFECTIVENESS - Therapy outcome analysis
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.gold_therapy_effectiveness`
PARTITION BY month
CLUSTER BY user_id
AS
SELECT
  user_id,
  device_name,
  DATE_TRUNC(session_date, MONTH) as month,
  -- Session counts
  COUNT(*) as total_sessions,
  COUNTIF(was_effective) as effective_sessions,
  COUNTIF(has_feedback) as sessions_with_feedback,
  -- Effectiveness metrics
  AVG(pain_reduction) as avg_pain_reduction,
  AVG(pain_reduction_pct) as avg_pain_reduction_pct,
  SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) as effectiveness_rate,
  -- Settings analysis
  AVG(initial_heat) as avg_initial_heat,
  AVG(initial_tens) as avg_initial_tens,
  AVG(final_heat) as avg_final_heat,
  AVG(final_tens) as avg_final_tens,
  -- User adjustments
  COUNTIF(user_adjusted) as sessions_adjusted,
  SAFE_DIVIDE(COUNTIF(user_adjusted), COUNT(*)) as adjustment_rate,
  -- Duration
  AVG(duration_minutes) as avg_duration_minutes,
  MAX(duration_minutes) as max_duration_minutes,
  -- Performance classification
  CASE 
    WHEN SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) >= 0.8 THEN 'Highly Effective'
    WHEN SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) >= 0.6 THEN 'Effective'
    WHEN SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) >= 0.4 THEN 'Moderately Effective'
    ELSE 'Low Effectiveness'
  END as effectiveness_category,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
GROUP BY user_id, device_name, DATE_TRUNC(session_date, MONTH);

-- 3. GOLD_MEDICATION_ADHERENCE - Medication tracking analytics
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.gold_medication_adherence`
CLUSTER BY user_id
AS
SELECT
  user_id,
  medication_name,
  medication_type,
  medication_status,
  -- Adherence metrics
  AVG(adherence_rate) as avg_adherence_rate,
  MAX(adherence_rate) as best_adherence_rate,
  MIN(adherence_rate) as worst_adherence_rate,
  -- Duration metrics
  AVG(days_on_medication) as avg_days_on_med,
  MAX(days_on_medication) as max_days_on_med,
  COUNT(*) as med_records,
  -- Adherence category distribution
  COUNTIF(adherence_category = 'High') as high_adherence_count,
  COUNTIF(adherence_category = 'Moderate') as moderate_adherence_count,
  COUNTIF(adherence_category = 'Low') as low_adherence_count,
  -- Missed doses estimation (assuming daily frequency)
  CAST((1 - AVG(adherence_rate)) * AVG(days_on_medication) AS INT64) as estimated_missed_doses,
  CAST(AVG(days_on_medication) AS INT64) as estimated_total_doses,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_medications`
GROUP BY user_id, medication_name, medication_type, medication_status;

-- 4. DIM_USERS - User dimension table
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.dim_users`
CLUSTER BY user_id
AS
WITH user_profile AS (
  SELECT
    JSON_VALUE(data, '$.userId') as user_id,
    JSON_VALUE(data, '$.email') as email,
    CAST(JSON_VALUE(data, '$.age') AS INT64) as age,
    JSON_VALUE(data, '$.age_group') as age_group,
    JSON_VALUE(data, '$.subscription_tier') as subscription_tier,
    DATE(TIMESTAMP(JSON_VALUE(data, '$.created_at'))) as account_created_date,
    ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(data, '$.userId') ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.user_health_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
)
SELECT
  user_id,
  email,
  age,
  age_group,
  subscription_tier,
  account_created_date,
  CURRENT_TIMESTAMP() as processed_at
FROM user_profile
WHERE rn = 1;

-- 5. DIM_DATE - Date dimension table
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.dim_date`
PARTITION BY date
CLUSTER BY date
AS
WITH date_range AS (
  SELECT date_day as date
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', DATE_ADD(CURRENT_DATE(), INTERVAL 365 DAY), INTERVAL 1 DAY)) AS date_day
)
SELECT
  date,
  EXTRACT(YEAR FROM date) as year,
  EXTRACT(MONTH FROM date) as month,
  EXTRACT(DAY FROM date) as day,
  EXTRACT(DAYOFWEEK FROM date) as day_of_week,
  FORMAT_DATE('%A', date) as day_name,
  FORMAT_DATE('%B', date) as month_name,
  EXTRACT(QUARTER FROM date) as quarter,
  EXTRACT(WEEK FROM date) as week_of_year,
  CASE 
    WHEN EXTRACT(DAYOFWEEK FROM date) IN (1, 7) THEN TRUE 
    ELSE FALSE 
  END as is_weekend,
  CURRENT_TIMESTAMP() as processed_at
FROM date_range;

-- 6. DIM_THERAPISTS - Therapist dimension (placeholder - populate from actual therapist data)
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.dim_therapists`
CLUSTER BY therapist_id
AS
WITH therapist_data AS (
  SELECT
    JSON_VALUE(data, '$.therapistId') as therapist_id,
    JSON_VALUE(data, '$.name') as name,
    JSON_VALUE(data, '$.specialization') as specialization,
    CAST(JSON_VALUE(data, '$.years_experience') AS INT64) as years_experience,
    JSON_VALUE(data, '$.certification') as certification,
    ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(data, '$.therapistId') ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.user_health_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
    AND JSON_VALUE(data, '$.therapistId') IS NOT NULL
)
SELECT
  COALESCE(therapist_id, 'UNKNOWN') as therapist_id,
  COALESCE(name, 'Not Assigned') as name,
  COALESCE(specialization, 'General') as specialization,
  COALESCE(years_experience, 0) as years_experience,
  COALESCE(certification, 'N/A') as certification,
  CURRENT_TIMESTAMP() as processed_at
FROM therapist_data
WHERE rn = 1
UNION ALL
SELECT 
  'UNKNOWN' as therapist_id,
  'Not Assigned' as name,
  'General' as specialization,
  0 as years_experience,
  'N/A' as certification,
  CURRENT_TIMESTAMP() as processed_at;

-- 7. FACT_HEALTH_METRICS - Health metrics fact table
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.fact_health_metrics`
PARTITION BY date
CLUSTER BY user_id
AS
WITH health_metrics AS (
  SELECT
    user_id,
    date,
    'sleep_duration' as metric_type,
    CAST(sleep_duration_mins AS FLOAT64) as metric_value,
    sleep_quality_score as quality_score
  FROM `junoplus-dev.junoplus_analytics_silver.silver_sleep_data`
  UNION ALL
  SELECT
    user_id,
    date,
    'steps' as metric_type,
    CAST(steps_count AS FLOAT64) as metric_value,
    CASE 
      WHEN steps_count >= 10000 THEN 1.0
      WHEN steps_count >= 7000 THEN 0.8
      WHEN steps_count >= 5000 THEN 0.6
      ELSE 0.4
    END as quality_score
  FROM `junoplus-dev.junoplus_analytics_silver.silver_user_health_data`
  WHERE steps_count IS NOT NULL
  UNION ALL
  SELECT
    user_id,
    date,
    'weight' as metric_type,
    weight_kg as metric_value,
    CASE 
      WHEN bmi BETWEEN 18.5 AND 25 THEN 1.0
      WHEN bmi BETWEEN 25 AND 30 THEN 0.7
      ELSE 0.5
    END as quality_score
  FROM `junoplus-dev.junoplus_analytics_silver.silver_user_health_data`
  WHERE weight_kg IS NOT NULL
  UNION ALL
  SELECT
    user_id,
    date,
    'heart_rate' as metric_type,
    CAST(heart_rate_avg AS FLOAT64) as metric_value,
    CASE 
      WHEN heart_rate_avg BETWEEN 60 AND 100 THEN 1.0
      ELSE 0.7
    END as quality_score
  FROM `junoplus-dev.junoplus_analytics_silver.silver_user_health_data`
  WHERE heart_rate_avg IS NOT NULL
)
SELECT
  ROW_NUMBER() OVER (ORDER BY user_id, date, metric_type) as metric_id,
  user_id,
  date,
  metric_type,
  metric_value,
  quality_score,
  CURRENT_TIMESTAMP() as processed_at
FROM health_metrics;

-- 8. ML_TRAINING_BASE - Base table for ML features
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.ml_training_base`
PARTITION BY session_date
CLUSTER BY user_id
AS
SELECT
  s.session_id,
  s.user_id,
  s.session_date,
  s.start_time,
  s.end_time,
  s.duration_minutes,
  s.device_name,
  -- Target variables
  s.pain_before,
  s.pain_after,
  s.pain_reduction,
  s.pain_reduction_pct,
  s.was_effective,
  -- Input features - initial settings (what AI recommended)
  s.initial_heat,
  s.initial_mode,
  s.initial_tens,
  -- Outcome features - final settings (what user settled on)
  s.final_heat,
  s.final_mode,
  s.final_tens,
  s.user_adjusted,
  -- Context features - period tracking
  p.cycle_day,
  p.cycle_phase,
  p.flow_intensity,
  p.pain_level as period_pain_level,
  p.high_pain_day,
  -- Context features - health data
  h.bmi,
  h.heart_rate_avg,
  h.steps_count,
  h.activity_level,
  h.stress_level,
  -- Context features - sleep
  sl.sleep_duration_mins,
  sl.sleep_quality_score,
  sl.sleep_category,
  -- Context features - medications
  CASE WHEN m.user_id IS NOT NULL THEN TRUE ELSE FALSE END as on_medication,
  m.adherence_category,
  -- User demographics
  u.age,
  u.age_group,
  u.subscription_tier,
  -- Time features
  EXTRACT(HOUR FROM s.start_time) as hour_of_day,
  EXTRACT(DAYOFWEEK FROM s.session_date) as day_of_week,
  CASE 
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 6 AND 11 THEN 'morning'
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 12 AND 17 THEN 'afternoon'
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 18 AND 21 THEN 'evening'
    ELSE 'night'
  END as time_of_day,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions` s
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_period_tracking` p
  ON s.user_id = p.user_id AND s.session_date = p.date
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_user_health_data` h
  ON s.user_id = h.user_id AND s.session_date = h.date
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_sleep_data` sl
  ON s.user_id = sl.user_id AND s.session_date = sl.date
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_medications` m
  ON s.user_id = m.user_id AND m.medication_status = 'Active'
LEFT JOIN `junoplus-dev.junoplus_analytics_gold.dim_users` u
  ON s.user_id = u.user_id
WHERE s.has_feedback = TRUE;
