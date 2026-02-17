-- Quality Layer: Data Monitoring & Validation
-- Purpose: Track data freshness, quality metrics, and anomalies
-- Created: 2026-01-15

-- ============================================================================
-- STEP 1: Create Quality Dataset
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS `junoplus-dev.junoplus_analytics_quality`
OPTIONS(
  location="us-central1",
  description="Data quality monitoring and validation layer"
);

-- ============================================================================
-- STEP 2: Data Freshness Tracking
-- ============================================================================

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_quality.data_freshness`
PARTITION BY DATE(checked_at)
CLUSTER BY table_name, is_stale
AS
WITH table_freshness AS (
  -- Silver layer tables
  SELECT
    'silver.silver_user_profiles' as table_name,
    'Silver' as layer,
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_silver.silver_user_profiles`) as last_updated
  
  UNION ALL
  
  SELECT
    'silver.silver_therapy_sessions',
    'Silver',
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`)
  
  UNION ALL
  
  SELECT
    'silver.silver_period_tracking',
    'Silver',
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_silver.silver_period_tracking`)
  
  UNION ALL
  
  SELECT
    'silver.silver_medications',
    'Silver',
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_silver.silver_medications`)
  
  -- Gold layer tables
  UNION ALL
  
  SELECT
    'gold.ml_training_base_v2',
    'Gold',
    CURRENT_TIMESTAMP() -- Gold tables don't have processed_at yet
  
  UNION ALL
  
  SELECT
    'gold.user_analytics_v1',
    'Gold',
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_gold.user_analytics_v1`)
  
  UNION ALL
  
  SELECT
    'gold.daily_metrics_v1',
    'Gold',
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_gold.daily_metrics_v1`)
  
  UNION ALL
  
  SELECT
    'gold.device_performance_v1',
    'Gold',
    (SELECT MAX(processed_at) FROM `junoplus-dev.junoplus_analytics_gold.device_performance_v1`)
  
  -- Semantic layer
  UNION ALL
  
  SELECT
    'semantic.user_health_dashboard_v1',
    'Semantic',
    (SELECT MAX(refreshed_at) FROM `junoplus-dev.junoplus_analytics_semantic.user_health_dashboard_v1`)
)
SELECT
  table_name,
  layer,
  last_updated,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_updated, HOUR) as hours_stale,
  CASE 
    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_updated, HOUR) > 48 THEN TRUE
    ELSE FALSE
  END as is_stale,
  CURRENT_TIMESTAMP() as checked_at
FROM table_freshness;

-- ============================================================================
-- STEP 3: Data Quality Metrics
-- ============================================================================

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_quality.data_quality_metrics`
PARTITION BY DATE(checked_at)
CLUSTER BY table_name, status
AS
WITH quality_checks AS (
  -- Check 1: Null rate in pain reduction
  SELECT
    'gold.ml_training_base_v2' as table_name,
    'null_rate_pain_reduction' as metric_name,
    'data_completeness' as metric_category,
    SAFE_DIVIDE(
      COUNTIF(pain_reduction IS NULL),
      COUNT(*)
    ) * 100 as metric_value,
    5.0 as threshold,
    'Values should be <5% null' as description
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
  
  UNION ALL
  
  -- Check 2: Effectiveness rate
  SELECT
    'gold.ml_training_base_v2',
    'effectiveness_rate',
    'business_metric',
    AVG(CASE WHEN was_effective THEN 1.0 ELSE 0.0 END) * 100,
    50.0,
    'At least 50% of sessions should be effective'
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
  
  UNION ALL
  
  -- Check 3: Duplicate sessions
  SELECT
    'gold.ml_training_base_v2',
    'duplicate_rate',
    'data_integrity',
    SAFE_DIVIDE(
      (COUNT(*) - COUNT(DISTINCT session_id)),
      COUNT(*)
    ) * 100,
    1.0,
    'Duplicate sessions should be <1%'
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
  
  UNION ALL
  
  -- Check 4: Null user IDs
  SELECT
    'gold.ml_training_base_v2',
    'null_rate_user_id',
    'data_completeness',
    SAFE_DIVIDE(
      COUNTIF(user_id IS NULL),
      COUNT(*)
    ) * 100,
    0.1,
    'User IDs should be >99.9% complete'
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
  
  UNION ALL
  
  -- Check 5: Future dates
  SELECT
    'gold.ml_training_base_v2',
    'future_dates',
    'data_validity',
    SAFE_DIVIDE(
      COUNTIF(session_date > CURRENT_DATE()),
      COUNT(*)
    ) * 100,
    0.0,
    'No future dates should exist'
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
  
  UNION ALL
  
  -- Check 6: User analytics completeness
  SELECT
    'gold.user_analytics_v1',
    'users_with_sessions',
    'data_completeness',
    SAFE_DIVIDE(
      COUNTIF(total_sessions > 0),
      COUNT(*)
    ) * 100,
    100.0,
    'All users should have at least 1 session'
  FROM `junoplus-dev.junoplus_analytics_gold.user_analytics_v1`
  
  UNION ALL
  
  -- Check 7: Daily metrics coverage
  SELECT
    'gold.daily_metrics_v1',
    'days_with_data',
    'data_completeness',
    COUNT(DISTINCT session_date) * 1.0,
    30.0,
    'Should have at least 30 days of data'
  FROM `junoplus-dev.junoplus_analytics_gold.daily_metrics_v1`
)
SELECT
  table_name,
  metric_name,
  metric_category,
  metric_value,
  threshold,
  description,
  CASE
    -- Completeness checks: FAIL if above threshold
    WHEN metric_category = 'data_completeness' AND metric_value > threshold THEN 'FAIL'
    -- Business metrics: WARN if below threshold
    WHEN metric_category = 'business_metric' AND metric_value < threshold THEN 'WARN'
    -- Integrity checks: FAIL if above threshold
    WHEN metric_category = 'data_integrity' AND metric_value > threshold THEN 'FAIL'
    -- Validity checks: FAIL if above threshold (should be 0)
    WHEN metric_category = 'data_validity' AND metric_value > threshold THEN 'FAIL'
    ELSE 'PASS'
  END as status,
  CURRENT_TIMESTAMP() as checked_at
FROM quality_checks;

-- ============================================================================
-- STEP 4: Row Count Tracking
-- ============================================================================

CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_quality.row_count_tracking`
PARTITION BY DATE(checked_at)
CLUSTER BY table_name, is_anomaly
AS
WITH current_counts AS (
  SELECT 'gold.ml_training_base_v2' as table_name,
         COUNT(*) as row_count
  FROM `junoplus-dev.junoplus_analytics_gold.ml_training_base_v2`
  
  UNION ALL
  
  SELECT 'gold.user_analytics_v1',
         COUNT(*)
  FROM `junoplus-dev.junoplus_analytics_gold.user_analytics_v1`
  
  UNION ALL
  
  SELECT 'gold.daily_metrics_v1',
         COUNT(*)
  FROM `junoplus-dev.junoplus_analytics_gold.daily_metrics_v1`
  
  UNION ALL
  
  SELECT 'gold.device_performance_v1',
         COUNT(*)
  FROM `junoplus-dev.junoplus_analytics_gold.device_performance_v1`
  
  UNION ALL
  
  SELECT 'silver.user_health_data_latest',
         COUNT(*)
  FROM `junoplus-dev.junoplus_analytics_silver.silver_user_profiles`
  
  UNION ALL
  
  SELECT 'silver.therapy_sessions_latest',
         COUNT(*)
  FROM `junoplus-dev.junoplus_analytics_silver.silver_therapy_sessions`
),
previous_counts AS (
  SELECT 
    table_name,
    row_count as previous_row_count
  FROM `junoplus-dev.junoplus_analytics_quality.row_count_tracking`
  WHERE DATE(checked_at) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY table_name ORDER BY checked_at DESC) = 1
)
SELECT
  c.table_name,
  c.row_count,
  COALESCE(p.previous_row_count, c.row_count) as previous_row_count,
  SAFE_DIVIDE(
    (c.row_count - COALESCE(p.previous_row_count, c.row_count)) * 100.0,
    COALESCE(p.previous_row_count, c.row_count)
  ) as change_pct,
  CASE
    -- Flag if row count drops > 10% or increases > 50%
    WHEN SAFE_DIVIDE(
      (c.row_count - COALESCE(p.previous_row_count, c.row_count)) * 100.0,
      COALESCE(p.previous_row_count, c.row_count)
    ) < -10 THEN TRUE
    WHEN SAFE_DIVIDE(
      (c.row_count - COALESCE(p.previous_row_count, c.row_count)) * 100.0,
      COALESCE(p.previous_row_count, c.row_count)
    ) > 50 THEN TRUE
    ELSE FALSE
  END as is_anomaly,
  CURRENT_TIMESTAMP() as checked_at
FROM current_counts c
LEFT JOIN previous_counts p ON c.table_name = p.table_name;

-- ============================================================================
-- STEP 5: Unified Quality Dashboard View
-- ============================================================================

CREATE OR REPLACE VIEW `junoplus-dev.junoplus_analytics_quality.quality_dashboard_v1` AS
SELECT
  'Freshness' as check_type,
  table_name,
  layer,
  CONCAT('Stale: ', CAST(hours_stale AS STRING), ' hours') as metric,
  CASE WHEN is_stale THEN 'FAIL' ELSE 'PASS' END as status,
  checked_at
FROM `junoplus-dev.junoplus_analytics_quality.data_freshness`
WHERE DATE(checked_at) = CURRENT_DATE()

UNION ALL

SELECT
  'Quality' as check_type,
  table_name,
  metric_category as layer,
  CONCAT(metric_name, ': ', CAST(ROUND(metric_value, 2) AS STRING), 
         ' (threshold: ', CAST(threshold AS STRING), ')') as metric,
  status,
  checked_at
FROM `junoplus-dev.junoplus_analytics_quality.data_quality_metrics`
WHERE DATE(checked_at) = CURRENT_DATE()

UNION ALL

SELECT
  'Row Count' as check_type,
  table_name,
  'data_volume' as layer,
  CONCAT('Rows: ', CAST(row_count AS STRING), 
         ' (change: ', CAST(ROUND(change_pct, 1) AS STRING), '%)') as metric,
  CASE WHEN is_anomaly THEN 'WARN' ELSE 'PASS' END as status,
  checked_at
FROM `junoplus-dev.junoplus_analytics_quality.row_count_tracking`
WHERE DATE(checked_at) = CURRENT_DATE();

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

-- Run this to verify the quality layer is working:
SELECT 
  check_type,
  status,
  COUNT(*) as check_count
FROM `junoplus-dev.junoplus_analytics_quality.quality_dashboard_v1`
GROUP BY check_type, status
ORDER BY check_type, 
  CASE status WHEN 'FAIL' THEN 1 WHEN 'WARN' THEN 2 ELSE 3 END;
