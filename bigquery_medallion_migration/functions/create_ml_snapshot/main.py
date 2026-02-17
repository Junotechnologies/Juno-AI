"""
Cloud Function to create ML dataset snapshots
Triggered by: Cloud Scheduler (weekly on Sundays at 4 AM UTC)
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
    """Create a weekly snapshot of ml_training_base_v2"""
    
    PROJECT_ID = os.environ.get('PROJECT_ID', 'junoplus-dev')
    DATASET_GOLD = os.environ.get('GOLD_DATASET_ID', 'junoplus_analytics_gold_dev')
    
    client = bigquery.Client(project=PROJECT_ID)
    start_time = datetime.now()
    
    # Generate snapshot name with timestamp
    snapshot_name = f"snapshot_{start_time.strftime('%Y%m%d')}"
    snapshot_table = f"ml_snapshot_{snapshot_name}"
    
    logger.info(f"📸 Creating ML snapshot: {snapshot_name}")
    
    try:
        # Create snapshot table (full copy of ml_training_base_v2)
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
        
        job = client.query(snapshot_query)
        job.result()  # Wait for completion
        
        # Get snapshot statistics
        table_ref = client.get_table(f"{PROJECT_ID}.{DATASET_GOLD}.{snapshot_table}")
        row_count = table_ref.num_rows
        size_mb = table_ref.num_bytes / (1024 * 1024)
        
        logger.info(f"✅ Snapshot table created: {snapshot_table}")
        logger.info(f"   Rows: {row_count:,}")
        logger.info(f"   Size: {size_mb:.2f} MB")
        
        # Register snapshot metadata in dataset_registry
        stats_query = f"""
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
        
        client.query(stats_query).result()
        logger.info(f"✅ Snapshot registered in dataset_registry")
        
        # Get final statistics for logging
        registry_query = f"""
        SELECT *
        FROM `{PROJECT_ID}.{DATASET_GOLD}.dataset_registry`
        WHERE snapshot_id = '{snapshot_name}'
        """
        stats = client.query(registry_query).to_dataframe().iloc[0]
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        logger.info(f"")
        logger.info(f"📊 Snapshot Summary:")
        logger.info(f"   Snapshot ID: {snapshot_name}")
        logger.info(f"   Table: {snapshot_table}")
        logger.info(f"   Rows: {stats['row_count']:,}")
        logger.info(f"   Date Range: {stats['date_range_start']} to {stats['date_range_end']}")
        logger.info(f"   Unique Users: {stats['unique_users']}")
        logger.info(f"   With Feedback: {stats['sessions_with_feedback']:,}")
        logger.info(f"   Duration: {duration:.1f}s")
        logger.info(f"")
        logger.info(f"🔍 Query snapshot with:")
        logger.info(f"   SELECT * FROM `{PROJECT_ID}.{DATASET_GOLD}.{snapshot_table}`")
        
        return {
            'status': 'success',
            'snapshot_id': snapshot_name,
            'snapshot_table': snapshot_table,
            'row_count': int(stats['row_count']),
            'duration_seconds': duration
        }
        
    except Exception as e:
        logger.error(f"❌ Error creating snapshot: {str(e)}")
        raise
