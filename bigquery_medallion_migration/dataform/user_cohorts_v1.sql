-- Gold Layer: user_cohorts_v1
-- Cohort analysis and user segmentation based on effectiveness and engagement
-- Created from ml_training_data_v1
-- Clustered: age_group, user_segment

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_gold.user_cohorts_v1`
CLUSTER BY age_group, user_segment
AS
WITH user_first_session AS (
  SELECT 
    userId,
    MIN(session_date) as first_session_date,
    EXTRACT(MONTH FROM MIN(session_date)) as cohort_month,
    EXTRACT(YEAR FROM MIN(session_date)) as cohort_year
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1`
  WHERE userId IS NOT NULL AND session_date IS NOT NULL
  GROUP BY userId
),
user_metrics AS (
  SELECT 
    m.userId,
    ufs.first_session_date,
    ufs.cohort_month,
    ufs.cohort_year,
    COUNT(DISTINCT m.session_date) as total_sessions,
    ROUND(AVG(SAFE_CAST(m.pain_reduction_percentage AS FLOAT64)), 4) as avg_effectiveness,
    ROUND(AVG(SAFE_CAST(m.therapyDuration AS FLOAT64)), 2) as avg_duration,
    ROUND(AVG(SAFE_CAST(m.target_heat_level AS FLOAT64)), 2) as avg_heat_level,
    ROUND(AVG(SAFE_CAST(m.target_tens_level AS FLOAT64)), 2) as avg_tens_level,
    MAX(m.age_group) as age_group
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_data_v1` m
  INNER JOIN user_first_session ufs ON m.userId = ufs.userId
  WHERE m.userId IS NOT NULL
  GROUP BY m.userId, ufs.first_session_date, ufs.cohort_month, ufs.cohort_year
  HAVING COUNT(DISTINCT m.session_date) > 5
)
SELECT
  userId,
  first_session_date,
  cohort_month,
  cohort_year,
  total_sessions,
  avg_effectiveness,
  avg_duration,
  avg_heat_level,
  avg_tens_level,
  age_group,
  CASE 
    WHEN avg_effectiveness >= 0.75 THEN 'High Effectiveness'
    WHEN avg_effectiveness >= 0.50 THEN 'Medium Effectiveness'
    ELSE 'Low Effectiveness'
  END as user_segment,
  CASE 
    WHEN EXTRACT(YEAR FROM CURRENT_DATE()) - cohort_year = 0 THEN 'New (Current Year)'
    WHEN EXTRACT(YEAR FROM CURRENT_DATE()) - cohort_year = 1 THEN '1 Year Old'
    ELSE 'Established (2+ Years)'
  END as cohort_age_group,
  CURRENT_TIMESTAMP() as last_updated
FROM user_metrics
