-- Gold Layer: Period Cycle Analytics
-- Analyze period patterns, regularity, and predictions

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.gold_period_cycle_analytics`
PARTITION BY month
CLUSTER BY user_id
AS
WITH monthly_tracking AS (
  SELECT
    user_id,
    DATE_TRUNC(date, MONTH) as month,
    COUNT(*) as days_tracked,
    COUNTIF(flow_intensity IS NOT NULL) as days_with_flow,
    AVG(CASE WHEN pain_level IS NOT NULL THEN pain_level END) as avg_pain_level,
    MAX(pain_level) as max_pain_level,
    STRING_AGG(DISTINCT symptoms, ', ') as common_symptoms,
    COUNTIF(high_pain_day) as high_pain_days
  FROM `junoplus-dev.junoplus_analytics_silver.silver_period_tracking`
  GROUP BY user_id, DATE_TRUNC(date, MONTH)
),
user_cycle_info AS (
  SELECT
    user_id,
    cycle_length,
    period_length,
    avg_cycle_length,
    avg_period_length,
    cycle_variance,
    has_irregular_cycles,
    cycle_regularity,
    total_cycles_logged
  FROM `junoplus-dev.junoplus_analytics_silver.silver_user_profiles`
)
SELECT
  t.user_id,
  t.month,
  t.days_tracked,
  t.days_with_flow,
  t.avg_pain_level,
  t.max_pain_level,
  t.common_symptoms,
  t.high_pain_days,
  -- Cycle info from user profile
  u.cycle_length,
  u.period_length,
  u.avg_cycle_length,
  u.avg_period_length,
  u.cycle_variance,
  u.has_irregular_cycles,
  u.cycle_regularity,
  u.total_cycles_logged,
  -- Insights
  CASE 
    WHEN t.avg_pain_level >= 7 THEN 'Severe Pain'
    WHEN t.avg_pain_level >= 5 THEN 'Moderate Pain'
    WHEN t.avg_pain_level >= 3 THEN 'Mild Pain'
    ELSE 'Low Pain'
  END as pain_severity_category,
  SAFE_DIVIDE(t.high_pain_days, t.days_with_flow) as high_pain_day_ratio,
  CURRENT_TIMESTAMP() as processed_at
FROM monthly_tracking t
LEFT JOIN user_cycle_info u ON t.user_id = u.user_id;
