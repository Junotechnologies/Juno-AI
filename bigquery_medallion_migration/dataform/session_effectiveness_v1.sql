-- Gold Layer: session_effectiveness_v1
-- Analyzes therapy session effectiveness by cycle phase, pain level, and time of day
-- Created from ml_training_data_v1
-- Partitioned: session_date | Clustered: cycle_phase_estimated, period_pain_level

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.session_effectiveness_v1`
PARTITION BY session_date
CLUSTER BY cycle_phase_estimated, period_pain_level
AS
SELECT
  sessionId as session_id,
  userId,
  session_date,
  cycle_phase_estimated,
  period_pain_level,
  therapyDuration as therapy_duration,
  pain_reduction_percentage,
  target_heat_level,
  target_tens_level,
  time_of_day_category as time_of_day,
  CASE 
    WHEN SAFE_CAST(pain_reduction_percentage AS FLOAT64) >= 0.75 THEN 'High Effectiveness'
    WHEN SAFE_CAST(pain_reduction_percentage AS FLOAT64) >= 0.50 THEN 'Medium Effectiveness'
    ELSE 'Low Effectiveness'
  END as effectiveness_score,
  was_effective,
  pain_level_before,
  pain_level_after,
  deviceName,
  deviceType,
  CURRENT_TIMESTAMP() as last_updated
FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`
WHERE pain_reduction_percentage IS NOT NULL
  AND therapyDuration IS NOT NULL
  AND session_date IS NOT NULL
  AND cycle_phase_estimated IS NOT NULL
