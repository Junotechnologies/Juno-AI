-- Create remaining Gold tables individually

-- GOLD_THERAPY_EFFECTIVENESS
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.gold_therapy_effectiveness`
PARTITION BY month
CLUSTER BY user_id
AS
SELECT
  user_id,
  device_name,
  DATE_TRUNC(session_date, MONTH) as month,
  COUNT(*) as total_sessions,
  COUNTIF(was_effective) as effective_sessions,
  COUNTIF(has_feedback) as sessions_with_feedback,
  AVG(pain_reduction) as avg_pain_reduction,
  AVG(pain_reduction_pct) as avg_pain_reduction_pct,
  SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) as effectiveness_rate,
  AVG(initial_heat) as avg_initial_heat,
  AVG(initial_tens) as avg_initial_tens,
  AVG(final_heat) as avg_final_heat,
  AVG(final_tens) as avg_final_tens,
  COUNTIF(user_adjusted) as sessions_adjusted,
  SAFE_DIVIDE(COUNTIF(user_adjusted), COUNT(*)) as adjustment_rate,
  AVG(duration_minutes) as avg_duration_minutes,
  MAX(duration_minutes) as max_duration_minutes,
  CASE 
    WHEN SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) >= 0.8 THEN 'Highly Effective'
    WHEN SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) >= 0.6 THEN 'Effective'
    WHEN SAFE_DIVIDE(COUNTIF(was_effective), COUNT(*)) >= 0.4 THEN 'Moderately Effective'
    ELSE 'Low Effectiveness'
  END as effectiveness_category,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
GROUP BY user_id, device_name, DATE_TRUNC(session_date, MONTH);
