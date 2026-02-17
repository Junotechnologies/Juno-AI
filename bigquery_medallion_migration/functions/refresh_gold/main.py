"""
Cloud Function to refresh Gold layer tables
Triggered by: Cloud Scheduler (weekly Sunday 3 AM UTC)
Runtime: Python 3.11
"""
import functions_framework
from google.cloud import bigquery
import logging
import os
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@functions_framework.http
def main(request):
    """Refresh all Gold layer tables in dependency order"""
    
    PROJECT_ID = os.environ.get('PROJECT_ID', 'junoplus-dev')
    DATASET_GOLD = os.environ.get('GOLD_DATASET_ID', 'junoplus_analytics_gold_dev')
    DATASET_SILVER = os.environ.get('SILVER_DATASET_ID', '{DATASET_SILVER}_dev')
    DATASET_SEMANTIC = 'junoplus_analytics_semantic'
    
    client = bigquery.Client(project=PROJECT_ID)
    start_time = datetime.now()
    
    logger.info(f"🔄 Starting Gold layer refresh at {start_time}")
    
    # Tables must be refreshed in order due to dependencies
    tables_config = [
        {
            'name': 'user_analytics_v1',
            'query': f"""
                CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET_GOLD}.user_analytics_v1`
                CLUSTER BY user_id, user_segment
                AS
                WITH user_stats AS (
                  SELECT 
                    user_id,
                    COUNT(*) as total_sessions,
                    AVG(duration_minutes) as avg_duration,
                    AVG(pain_reduction_pct) as avg_effectiveness,
                    AVG(final_heat) as preferred_heat,
                    AVG(final_tens) as preferred_tens
                  FROM `{PROJECT_ID}.{DATASET_SILVER}.silver_therapy_sessions`
                  GROUP BY user_id
                ),
                user_details AS (
                  SELECT 
                    user_id,
                    age,
                    CASE 
                      WHEN age < 25 THEN '18-24'
                      WHEN age < 35 THEN '25-34'
                      WHEN age < 45 THEN '35-44'
                      WHEN age < 55 THEN '45-54'
                      ELSE '55+'
                    END as age_group
                  FROM `{PROJECT_ID}.{DATASET_SILVER}.silver_user_profiles`
                )
                SELECT 
                  s.*,
                  d.age,
                  d.age_group,
                  CASE 
                    WHEN s.total_sessions < 5 THEN 'New User'
                    WHEN s.total_sessions < 20 THEN 'Regular User'
                    ELSE 'Power User'
                  END as user_segment,
                  CURRENT_TIMESTAMP() AS processed_at
                FROM user_stats s
                LEFT JOIN user_details d ON s.user_id = d.user_id
            """
        },
        {
            'name': 'daily_metrics_v1',
            'query': f"""
                CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET_GOLD}.daily_metrics_v1`
                PARTITION BY session_date
                CLUSTER BY session_date
                AS
                SELECT 
                  session_date,
                  COUNT(*) as session_count,
                  COUNT(DISTINCT user_id) as active_users,
                  AVG(duration_minutes) as avg_duration,
                  AVG(pain_reduction_pct) as avg_effectiveness,
                  AVG(final_heat) as avg_heat,
                  AVG(final_tens) as avg_tens,
                  CURRENT_TIMESTAMP() AS processed_at
                FROM `{PROJECT_ID}.{DATASET_SILVER}.silver_therapy_sessions`
                GROUP BY session_date
            """
        },
        {
            'name': 'ml_training_base_v2',
            'query': f"""
                CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET_GOLD}.ml_training_base_v2`
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
                  -- Target variables
                  s.pain_before,
                  s.pain_after,
                  s.pain_reduction,
                  s.pain_reduction_pct,
                  s.was_effective,
                  -- Input features
                  s.initial_heat,
                  s.initial_mode,
                  s.initial_tens,
                  -- Outcome features
                  s.final_heat,
                  s.final_mode,
                  s.final_tens,
                  s.user_adjusted,
                  -- User features
                  u.age,
                  -- Time features
                  EXTRACT(HOUR FROM s.start_time) as hour_of_day,
                  EXTRACT(DAYOFWEEK FROM s.session_date) as day_of_week,
                  CURRENT_TIMESTAMP() as processed_at
                FROM `{PROJECT_ID}.{DATASET_SILVER}.silver_therapy_sessions` s
                LEFT JOIN `{PROJECT_ID}.{DATASET_SILVER}.silver_user_profiles` u
                  ON s.user_id = u.user_id
                WHERE s.has_feedback = TRUE
            """
        }
    ]
    
    # Also refresh semantic layer
    semantic_config = {
        'name': 'user_health_dashboard_v1',
        'query': f"""
            CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET_SEMANTIC}.user_health_dashboard_v1`
            AS
            SELECT
              ua.user_id,
              ua.age_group,
              ua.total_sessions,
              ua.avg_duration,
              ua.avg_effectiveness,
              ua.user_segment,
              CASE
                WHEN ua.avg_effectiveness >= 0.7 THEN 'Highly Effective'
                WHEN ua.avg_effectiveness >= 0.5 THEN 'Effective'
                ELSE 'Needs Improvement'
              END as effectiveness_level,
              CURRENT_TIMESTAMP() as refreshed_at
            FROM `{PROJECT_ID}.{DATASET_GOLD}.user_analytics_v1` ua
        """
    }
    
    results = []
    
    # Refresh Gold tables
    for table_config in tables_config:
        table_name = table_config['name']
        try:
            logger.info(f"  → Refreshing gold.{table_name}...")
            
            job = client.query(table_config['query'])
            job.result()
            
            table_ref = client.get_table(f"{PROJECT_ID}.{DATASET_GOLD}.{table_name}")
            row_count = table_ref.num_rows
            
            logger.info(f"  ✅ gold.{table_name} refreshed ({row_count:,} rows)")
            results.append({
                'table': f"gold.{table_name}",
                'status': 'success',
                'rows': row_count
            })
            
        except Exception as e:
            logger.error(f"  ❌ Error refreshing gold.{table_name}: {str(e)}")
            results.append({
                'table': f"gold.{table_name}",
                'status': 'error',
                'error': str(e)
            })
    
    # Refresh Semantic table
    try:
        logger.info(f"  → Refreshing semantic.{semantic_config['name']}...")
        
        job = client.query(semantic_config['query'])
        job.result()
        
        table_ref = client.get_table(f"{PROJECT_ID}.{DATASET_SEMANTIC}.{semantic_config['name']}")
        row_count = table_ref.num_rows
        
        logger.info(f"  ✅ semantic.{semantic_config['name']} refreshed ({row_count:,} rows)")
        results.append({
            'table': f"semantic.{semantic_config['name']}",
            'status': 'success',
            'rows': row_count
        })
        
    except Exception as e:
        logger.error(f"  ❌ Error refreshing semantic.{semantic_config['name']}: {str(e)}")
        results.append({
            'table': f"semantic.{semantic_config['name']}",
            'status': 'error',
            'error': str(e)
        })
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    success_count = sum(1 for r in results if r['status'] == 'success')
    total_count = len(results)
    
    logger.info(f"✅ Gold layer refresh complete: {success_count}/{total_count} tables successful ({duration:.1f}s)")
    
    # Create weekly ML snapshot after successful gold refresh
    snapshot_info = None
    if success_count == total_count:  # Only create snapshot if all tables refreshed successfully
        try:
            logger.info(f"")
            logger.info(f"📸 Creating weekly ML snapshot...")
            
            snapshot_name = f"snapshot_{datetime.now().strftime('%Y%m%d')}"
            snapshot_table = f"ml_snapshot_{snapshot_name}"
            
            # Create snapshot table
            snapshot_query = f"""
            CREATE TABLE `{PROJECT_ID}.{DATASET_GOLD}.{snapshot_table}`
            PARTITION BY session_date
            CLUSTER BY user_id
            AS
            SELECT
              '{snapshot_name}' as snapshot_id,
              CURRENT_TIMESTAMP() as snapshot_created_at,
              *
            FROM `{PROJECT_ID}.{DATASET_GOLD}.ml_training_base_v2`
            """
            
            client.query(snapshot_query).result()
            
            # Get snapshot stats
            table_ref = client.get_table(f"{PROJECT_ID}.{DATASET_GOLD}.{snapshot_table}")
            snapshot_rows = table_ref.num_rows
            snapshot_size_mb = table_ref.num_bytes / (1024 * 1024)
            
            # Register in dataset_registry
            registry_query = f"""
            INSERT INTO `{PROJECT_ID}.{DATASET_GOLD}.dataset_registry`
            (snapshot_id, created_at, row_count, date_range_start, date_range_end,
             unique_users, sessions_with_feedback, creation_method, schema_version)
            SELECT
              '{snapshot_name}' as snapshot_id,
              CURRENT_TIMESTAMP() as created_at,
              COUNT(*) as row_count,
              MIN(session_date) as date_range_start,
              MAX(session_date) as date_range_end,
              COUNT(DISTINCT user_id) as unique_users,
              COUNTIF(pain_reduction IS NOT NULL) as sessions_with_feedback,
              'automated_weekly' as creation_method,
              'v2' as schema_version
            FROM `{PROJECT_ID}.{DATASET_GOLD}.{snapshot_table}`
            WHERE snapshot_id = '{snapshot_name}'
            """
            
            client.query(registry_query).result()
            
            logger.info(f"✅ Snapshot created: {snapshot_table}")
            logger.info(f"   Rows: {snapshot_rows:,}")
            logger.info(f"   Size: {snapshot_size_mb:.2f} MB")
            
            snapshot_info = {
                'snapshot_id': snapshot_name,
                'snapshot_table': snapshot_table,
                'rows': snapshot_rows,
                'size_mb': round(snapshot_size_mb, 2)
            }
            
        except Exception as e:
            logger.error(f"❌ Error creating snapshot: {str(e)}")
            snapshot_info = {'status': 'error', 'error': str(e)}
    else:
        logger.warning(f"⚠️  Skipping snapshot creation due to table refresh failures")
    
    return {
        'status': 'completed',
        'duration_seconds': duration,
        'tables_processed': total_count,
        'tables_successful': success_count,
        'results': results,
        'snapshot': snapshot_info,
        'timestamp': end_time.isoformat()
    }
