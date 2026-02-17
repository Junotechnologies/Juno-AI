import functions_framework
from google.cloud import bigquery
import json
import logging
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@functions_framework.http
def main(request):
    """
    Cloud Function to refresh Silver layer tables in BigQuery.
    Triggered by HTTP request from Cloud Scheduler.
    """
    client = bigquery.Client()
    project_id = os.environ.get('PROJECT_ID', 'junoplus-dev')
    dataset_silver = os.environ.get('SILVER_DATASET_ID', 'junoplus_analytics_silver_dev')
    dataset_bronze = os.environ.get('BRONZE_DATASET_ID', 'junoplus_analytics_dev')
    
    # Configure tables to refresh with enhanced logic
    tables_config = [
        {
            "name": "silver_therapy_sessions",
            "query": f"""
                CREATE OR REPLACE TABLE `{project_id}.{dataset_silver}.silver_therapy_sessions`
                PARTITION BY session_date
                CLUSTER BY user_id
                AS
                WITH session_data AS (
                  SELECT
                    document_id as session_id,
                    JSON_VALUE(path_params, '$.userId') as user_id,
                    JSON_VALUE(data, '$.deviceInformation.deviceId') as device_id,
                    JSON_VALUE(data, '$.deviceInformation.deviceName') as device_name,
                    DATE(TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64))) as session_date,
                    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyStartTime._seconds') AS INT64)) as start_time,
                    TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.sessionInfo.therapyEndTime._seconds') AS INT64)) as end_time,
                    CAST(JSON_VALUE(data, '$.sessionInfo.therapyDuration') AS INT64) as duration_minutes,
                    JSON_VALUE(data, '$.status') as status,
                    -- Settings
                    CAST(JSON_VALUE(data, '$.initialSettings.heatLevel') AS INT64) as initial_heat,
                    CAST(JSON_VALUE(data, '$.initialSettings.tensMode') AS INT64) as initial_mode,
                    CAST(JSON_VALUE(data, '$.initialSettings.tensLevel') AS INT64) as initial_tens,
                    CAST(JSON_VALUE(data, '$.finalSettings.heatLevel') AS INT64) as final_heat,
                    CAST(JSON_VALUE(data, '$.finalSettings.tensMode') AS INT64) as final_mode,
                    CAST(JSON_VALUE(data, '$.finalSettings.tensLevel') AS INT64) as final_tens,
                    -- Feedback
                    CAST(JSON_VALUE(data, '$.feedback.painLevelBefore') AS INT64) as pain_before,
                    CAST(JSON_VALUE(data, '$.feedback.painLevelAfter') AS INT64) as pain_after,
                    CAST(JSON_VALUE(data, '$.feedback.feedbackCompleted') AS BOOL) as has_feedback,
                    ROW_NUMBER() OVER (PARTITION BY document_id ORDER BY timestamp DESC) as rn
                  FROM `{project_id}.{dataset_bronze}.therapy_sessions_data_raw_changelog`
                  WHERE operation IN ('CREATE', 'UPDATE')
                    AND data IS NOT NULL
                )
                SELECT
                  * EXCEPT(rn),
                  -- Effectiveness metrics
                  CASE 
                    WHEN pain_before IS NOT NULL AND pain_after IS NOT NULL 
                    THEN pain_before - pain_after 
                    ELSE NULL 
                  END as pain_reduction,
                  CASE 
                    WHEN pain_before IS NOT NULL AND pain_after IS NOT NULL AND pain_before > 0
                    THEN SAFE_DIVIDE(pain_before - pain_after, pain_before)
                    ELSE NULL 
                  END as pain_reduction_pct,
                  CASE 
                    WHEN pain_before IS NOT NULL AND pain_after IS NOT NULL 
                      AND (pain_before - pain_after) >= 2 
                    THEN TRUE 
                    ELSE FALSE 
                  END as was_effective,
                  -- Adjustment tracking
                  CASE 
                    WHEN final_heat != initial_heat 
                      OR final_tens != initial_tens 
                      OR final_mode != initial_mode 
                    THEN TRUE 
                    ELSE FALSE 
                  END as user_adjusted,
                  CURRENT_TIMESTAMP() as processed_at
                FROM session_data
                WHERE rn = 1;
            """
        },
        {
            "name": "silver_user_profiles",
            "query": f"""
                CREATE OR REPLACE TABLE `{project_id}.{dataset_silver}.silver_user_profiles`
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
                  FROM `{project_id}.{dataset_bronze}.user_health_data_raw_changelog`
                  WHERE operation IN ('CREATE', 'UPDATE')
                    AND data IS NOT NULL
                    AND JSON_VALUE(data, '$.uid') IS NOT NULL
                )
                SELECT
                  * EXCEPT(rn),
                  DATE_DIFF(CURRENT_DATE(), DATE(date_of_birth), YEAR) as age,
                  CURRENT_TIMESTAMP() as processed_at
                FROM user_data
                WHERE rn = 1;
            """
        },
        {
            "name": "silver_medications",
            "query": f"""
                CREATE OR REPLACE TABLE `{project_id}.{dataset_silver}.silver_medications`
                CLUSTER BY user_id
                AS
                WITH med_array AS (
                  SELECT
                    document_id as user_id,
                    JSON_EXTRACT_ARRAY(data, '$.medications') as meds,
                    timestamp
                  FROM `{project_id}.{dataset_bronze}.medications_data_raw_changelog`
                  WHERE operation IN ('CREATE', 'UPDATE')
                    AND data IS NOT NULL
                ),
                flat_meds AS (
                  SELECT
                    user_id,
                    JSON_VALUE(med, '$.name') as medication_name,
                    JSON_VALUE(med, '$.dosage') as dosage,
                    JSON_VALUE(med, '$.frequency') as frequency,
                    JSON_VALUE(med, '$.frequencyUnit') as frequency_unit,
                    DATE(TIMESTAMP(JSON_VALUE(med, '$.startDate'))) as start_date,
                    CAST(JSON_VALUE(med, '$.isNotificationEnabled') AS BOOL) as notifications_enabled,
                    ROW_NUMBER() OVER (PARTITION BY user_id, JSON_VALUE(med, '$.name') ORDER BY timestamp DESC) as rn
                  FROM med_array,
                  UNNEST(meds) as med
                )
                SELECT
                  user_id,
                  medication_name,
                  dosage,
                  frequency,
                  frequency_unit,
                  start_date,
                  notifications_enabled,
                  CURRENT_TIMESTAMP() as processed_at
                FROM flat_meds
                WHERE rn = 1;
            """
        },
        {
            "name": "silver_period_tracking",
            "query": f"""
                CREATE OR REPLACE TABLE `{project_id}.{dataset_silver}.silver_period_tracking`
                CLUSTER BY user_id
                AS
                SELECT
                  JSON_VALUE(path_params, '$.userId') as user_id,
                  document_id as cycle_id,
                  JSON_VALUE(data, '$.status') as cycle_status,
                  TIMESTAMP_SECONDS(CAST(JSON_VALUE(data, '$.lastUpdate._seconds') AS INT64)) as last_update,
                  CURRENT_TIMESTAMP() as processed_at
                FROM `{project_id}.{dataset_bronze}.period_tracking_data_raw_latest`
                WHERE data IS NOT NULL;
            """
        }
    ]

    for table in tables_config:
        try:
            logger.info(f"Refreshing silver table: {table['name']}")
            query_job = client.query(table['query'])
            query_job.result()  
            logger.info(f"Successfully refreshed {table['name']}")
        except Exception as e:
            logger.error(f"Error refreshing {table['name']}: {str(e)}")
            continue

    return ('Silver layer refresh complete', 200)
