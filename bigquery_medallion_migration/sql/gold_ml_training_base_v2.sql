-- Updated ML Training Base - CORRECTED VERSION
-- Only includes fields that actually exist in the data

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
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
  -- Target variables (what we're predicting)
  s.pain_before,
  s.pain_after,
  s.pain_reduction,
  s.pain_reduction_pct,
  s.was_effective,
  -- Input features - initial settings (AI recommendations)
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
  -- Context features - user profile & cycle
  u.age,
  u.age_group,
  u.cycle_length,
  u.period_length,
  u.cycle_regularity,
  u.has_irregular_cycles,
  u.total_cycles_logged,
  -- Context features - medications (active on session date)
  CASE WHEN m.user_id IS NOT NULL THEN TRUE ELSE FALSE END as on_medication,
  m.medication_name,
  m.adherence_category,
  -- Time features
  EXTRACT(HOUR FROM s.start_time) as hour_of_day,
  EXTRACT(DAYOFWEEK FROM s.session_date) as day_of_week,
  CASE 
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 6 AND 11 THEN 'morning'
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 12 AND 17 THEN 'afternoon'
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 18 AND 21 THEN 'evening'
    ELSE 'night'
  END as time_of_day,
  -- Derived features
  CASE 
    WHEN p.cycle_day BETWEEN 1 AND 5 THEN TRUE 
    ELSE FALSE 
  END as is_during_period,
  CASE 
    WHEN p.cycle_day BETWEEN 14 AND 16 THEN TRUE 
    ELSE FALSE 
  END as is_during_ovulation,
  CURRENT_TIMESTAMP() as processed_at
FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions` s
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_period_tracking` p
  ON s.user_id = p.user_id AND s.session_date = p.date
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_user_profiles` u
  ON s.user_id = u.user_id
LEFT JOIN `junoplus-dev.junoplus_analytics_silver.silver_medications` m
  ON s.user_id = m.user_id AND m.medication_status = 'Active'
WHERE s.has_feedback = TRUE;
