-- Gold Layer: Analytics Tables
-- Purpose-specific aggregations for dashboards, reports, and analysis

-- 1. User Analytics Table - User-level metrics
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.user_analytics_v1`
CLUSTER BY (user_id, user_segment)
AS
WITH user_stats AS (
  SELECT 
    user_id,
    -- Session metrics
    COUNT(*) as total_sessions,
    MIN(session_date) as first_session_date,
    MAX(session_date) as last_session_date,
    DATE_DIFF(MAX(session_date), MIN(session_date), DAY) as days_active,
    
    -- Duration metrics
    AVG(duration_minutes) as avg_session_duration,
    MAX(duration_minutes) as max_session_duration,
    SUM(duration_minutes) as total_therapy_minutes,
    
    -- Pain & effectiveness
    AVG(pain_before) as avg_initial_pain,
    AVG(pain_after) as avg_final_pain,
    AVG(pain_reduction) as avg_pain_reduction,
    AVG(pain_reduction_pct) as avg_pain_reduction_pct,
    AVG(CASE WHEN was_effective THEN 1 ELSE 0 END) as effectiveness_rate,
    
    -- Device preferences
    AVG(final_heat) as preferred_heat_level,
    AVG(final_mode) as preferred_tens_mode,
    AVG(final_tens) as preferred_tens_level,
    
    -- Adjustment patterns
    AVG(CASE WHEN user_adjusted THEN 1 ELSE 0 END) as adjustment_rate
    
  FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
  GROUP BY user_id
)
SELECT
  *,
  -- User segmentation
  CASE 
    WHEN total_sessions < 5 THEN 'New User'
    WHEN total_sessions < 20 THEN 'Regular User'
    WHEN total_sessions < 50 THEN 'Active User'
    ELSE 'Power User'
  END as user_segment,
  
  -- Engagement level
  CASE
    WHEN days_active = 0 THEN 'Single Day'
    WHEN days_active < 7 THEN 'Week 1'
    WHEN days_active < 30 THEN 'Month 1'
    WHEN days_active < 90 THEN 'Quarter 1'
    ELSE 'Long-term'
  END as engagement_cohort,
  
  -- Effectiveness classification
  CASE
    WHEN avg_pain_reduction_pct >= 0.7 THEN 'Highly Effective'
    WHEN avg_pain_reduction_pct >= 0.5 THEN 'Effective'
    WHEN avg_pain_reduction_pct >= 0.3 THEN 'Moderately Effective'
    ELSE 'Low Effectiveness'
  END as effectiveness_category,
  
  CURRENT_TIMESTAMP() AS processed_at
FROM user_stats;

-- 2. Daily Metrics Table - Daily KPIs for monitoring
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.daily_metrics_v1`
PARTITION BY session_date
CLUSTER BY (session_date)
AS
SELECT 
  session_date,
  
  -- Volume metrics
  COUNT(*) as session_count,
  COUNT(DISTINCT user_id) as active_users,
  COUNT(DISTINCT CASE WHEN was_effective THEN user_id END) as effective_users,
  
  -- Session metrics
  AVG(duration_minutes) as avg_duration,
  SUM(duration_minutes) as total_therapy_minutes,
  
  -- Pain metrics
  AVG(pain_before) as avg_initial_pain,
  AVG(pain_after) as avg_final_pain,
  AVG(pain_reduction) as avg_pain_reduction,
  AVG(pain_reduction_pct) as avg_pain_reduction_pct,
  
  CURRENT_TIMESTAMP() AS processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
GROUP BY session_date;
  
  -- Effectiveness
  AVG(CASE WHEN was_effective THEN 1 ELSE 0 END) as effectiveness_rate,
  
  -- Device settings
  AVG(target_heat_level) as avg_heat_level,
  AVG(target_tens_mode) as avg_tens_mode,
  AVG(target_tens_level) as avg_tens_level,
  
  -- Adjustments
  AVG(CASE WHEN user_made_adjustments THEN 1 ELSE 0 END) as adjustment_rate,
  
  -- Time of day distribution
  COUNTIF(time_of_day_category_morning = 1) as morning_sessions,
  COUNTIF(time_of_day_category_afternoon = 1) as afternoon_sessions,
  COUNTIF(time_of_day_category_evening = 1) as evening_sessions,
  COUNTIF(time_of_day_category_night = 1) as night_sessions,
  
  -- Context
  AVG(CASE WHEN is_near_period THEN 1 ELSE 0 END) as period_usage_rate,
  AVG(CASE WHEN has_pain_medication THEN 1 ELSE 0 END) as medication_usage_rate,
  
  CURRENT_TIMESTAMP() AS processed_at
  
FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`
GROUP BY session_date;

-- 3. Device Performance Table
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.device_performance_v1`
CLUSTER BY (device_size)
AS
SELECT 
  device_size,
  
  -- Usage metrics
  COUNT(*) as total_sessions,
  COUNT(DISTINCT userId) as unique_users,
  
  -- Duration
  AVG(therapyDuration) as avg_duration,
  
  -- Effectiveness
  AVG(pain_reduction) as avg_pain_reduction,
  AVG(pain_reduction_percentage) as avg_pain_reduction_pct,
  AVG(CASE WHEN was_effective THEN 1 ELSE 0 END) as effectiveness_rate,
  
  -- Settings preferences
  AVG(target_heat_level) as avg_heat_level,
  AVG(target_tens_mode) as avg_tens_mode,
  AVG(target_tens_level) as avg_tens_level,
  
  -- Battery
  AVG(most_used_battery_level) as avg_battery_level,
  
  -- User satisfaction
  AVG(CASE WHEN user_made_adjustments THEN 1 ELSE 0 END) as adjustment_rate,
  
  CURRENT_TIMESTAMP() AS processed_at
  
FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`
GROUP BY device_size;

-- 4. Session Effectiveness Analysis
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.session_effectiveness_v1`
PARTITION BY session_date
CLUSTER BY (cycle_phase_estimated, period_pain_level)
AS
SELECT 
  session_date,
  cycle_phase_estimated,
  period_pain_level,
  flow_level,
  has_pain_medication,
  time_of_day_category_morning,
  time_of_day_category_afternoon,
  time_of_day_category_evening,
  time_of_day_category_night,
  
  -- Aggregated metrics
  COUNT(*) as session_count,
  AVG(pain_reduction) as avg_pain_reduction,
  AVG(pain_reduction_percentage) as avg_pain_reduction_pct,
  AVG(CASE WHEN was_effective THEN 1 ELSE 0 END) as effectiveness_rate,
  
  AVG(target_heat_level) as avg_heat,
  AVG(target_tens_level) as avg_tens,
  AVG(therapyDuration) as avg_duration,
  
  CURRENT_TIMESTAMP() AS processed_at
  
FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`
GROUP BY 
  session_date,
  cycle_phase_estimated,
  period_pain_level,
  flow_level,
  has_pain_medication,
  time_of_day_category_morning,
  time_of_day_category_afternoon,
  time_of_day_category_evening,
  time_of_day_category_night;

-- 5. User Cohort Analysis
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.user_cohorts_v1`
CLUSTER BY (cohort_month, age_group)
AS
WITH first_sessions AS (
  SELECT 
    userId,
    MIN(session_date) as first_session_date,
    DATE_TRUNC(MIN(session_date), MONTH) as cohort_month,
    MAX(age_group) as age_group
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`
  GROUP BY userId
),
cohort_activity AS (
  SELECT
    fs.cohort_month,
    fs.age_group,
    COUNT(DISTINCT fs.userId) as cohort_size,
    COUNT(DISTINCT CASE 
      WHEN t.session_date < DATE_ADD(fs.cohort_month, INTERVAL 30 DAY) THEN t.userId 
    END) as retained_month_1,
    COUNT(DISTINCT CASE 
      WHEN t.session_date BETWEEN DATE_ADD(fs.cohort_month, INTERVAL 30 DAY) 
        AND DATE_ADD(fs.cohort_month, INTERVAL 60 DAY) THEN t.userId 
    END) as retained_month_2,
    COUNT(DISTINCT CASE 
      WHEN t.session_date BETWEEN DATE_ADD(fs.cohort_month, INTERVAL 60 DAY) 
        AND DATE_ADD(fs.cohort_month, INTERVAL 90 DAY) THEN t.userId 
    END) as retained_month_3,
    AVG(t.pain_reduction_percentage) as avg_effectiveness
  FROM first_sessions fs
  LEFT JOIN `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1` t
    ON fs.userId = t.userId
  GROUP BY fs.cohort_month, fs.age_group
)
SELECT
  *,
  SAFE_DIVIDE(retained_month_1, cohort_size) as retention_rate_month_1,
  SAFE_DIVIDE(retained_month_2, cohort_size) as retention_rate_month_2,
  SAFE_DIVIDE(retained_month_3, cohort_size) as retention_rate_month_3,
  CURRENT_TIMESTAMP() AS processed_at
FROM cohort_activity;
