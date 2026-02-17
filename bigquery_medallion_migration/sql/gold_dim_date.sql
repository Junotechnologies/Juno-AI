-- DIM_DATE - Date dimension table
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
