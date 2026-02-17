-- Silver Layer: User Profiles
-- Source: user_health_data_raw_changelog
CREATE OR REPLACE TABLE `junoplus-dev.junoplus_analytics_silver.silver_user_profiles`
CLUSTER BY user_id
AS
WITH user_data AS (
  SELECT
    JSON_VALUE(data, '$.uid') as user_id,
    JSON_VALUE(data, '$.userEmail') as email,
    JSON_VALUE(data, '$.userName') as name,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.dateOfBirth._seconds') AS INT64)) as date_of_birth,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.signUpTimeStamp._seconds') AS INT64)) as signup_date,
    CAST(JSON_VALUE(data, '$.isOnboarded') AS BOOL) as is_onboarded,
    CAST(JSON_VALUE(data, '$.healthData.cycleLength') AS INT64) as cycle_length,
    CAST(JSON_VALUE(data, '$.healthData.periodLength') AS INT64) as period_length,
    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.healthData.lastPeriodDate._seconds') AS INT64)) as last_period_date,
    ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(data, '$.uid') ORDER BY timestamp DESC) as rn
  FROM `junoplus-dev.junoplus_analytics.user_health_data_raw_changelog`
  WHERE operation IN ('CREATE', 'UPDATE')
    AND data IS NOT NULL
    AND JSON_VALUE(data, '$.uid') IS NOT NULL
)
SELECT
  * EXCEPT(rn),
  DATE_DIFF(CURRENT_DATE(), DATE(date_of_birth), YEAR) as age,
  CASE 
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(date_of_birth), YEAR) < 25 THEN '18-24'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(date_of_birth), YEAR) < 35 THEN '25-34'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(date_of_birth), YEAR) < 45 THEN '35-44'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(date_of_birth), YEAR) < 55 THEN '45-54'
    ELSE '55+'
  END as age_group,
  -- Placeholders for advanced metrics used in Gold layer
  CAST(NULL AS FLOAT64) as avg_cycle_length,
  CAST(NULL AS FLOAT64) as avg_period_length,
  CAST(NULL AS FLOAT64) as cycle_variance,
  CAST(NULL AS STRING) as cycle_regularity,
  CAST(NULL AS INT64) as total_cycles_logged,
  CURRENT_TIMESTAMP() as processed_at
FROM user_data
WHERE rn = 1;
