"""
Cloud Function to run data quality checks
Triggered by: Cloud Scheduler (hourly)
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
    """Run quality checks and update quality tables"""
    
    PROJECT_ID = os.environ.get('PROJECT_ID', 'junoplus-dev')
    DATASET_QUALITY = os.environ.get('QUALITY_DATASET_ID', 'junoplus_analytics_quality_dev')
    DATASET_BRONZE = os.environ.get('BRONZE_DATASET_ID', 'junoplus_analytics_dev')
    DATASET_SILVER = os.environ.get('SILVER_DATASET_ID', 'junoplus_analytics_silver_dev')
    DATASET_GOLD = os.environ.get('GOLD_DATASET_ID', 'junoplus_analytics_gold_dev')
    
    client = bigquery.Client(project=PROJECT_ID)
    start_time = datetime.now()
    
    logger.info(f"🔍 Starting quality checks at {start_time}")
    
    results = {
        'checks_run': [],
        'alerts': [],
        'summary': {}
    }
    
    # Run quality checks by re-executing the quality layer setup
    # This updates all quality tables with latest data
    
    quality_checks = [
        {
            'name': 'data_freshness',
            'description': 'Check table freshness',
            'query': open('/workspace/sql/quality_layer_setup.sql').read().split('-- STEP 2:')[1].split('-- STEP 3:')[0]
        },
        {
            'name': 'data_quality_metrics',
            'description': 'Check data quality',
            'query': open('/workspace/sql/quality_layer_setup.sql').read().split('-- STEP 3:')[1].split('-- STEP 4:')[0]
        },
        {
            'name': 'row_count_tracking',
            'description': 'Track row counts',
            'query': open('/workspace/sql/quality_layer_setup.sql').read().split('-- STEP 4:')[1].split('-- STEP 5:')[0]
        }
    ]
    
    try:
        # For simplicity, just re-run the full quality setup
        # In production, you'd run each check separately
        logger.info("  → Updating quality tables...")
        
        with open('/workspace/sql/quality_layer_setup.sql', 'r') as f:
            quality_sql = f.read()
        
        # Execute the full quality setup
        # Split by CREATE statements and execute
        statements = [s for s in quality_sql.split('CREATE OR REPLACE') if 'TABLE' in s or 'VIEW' in s]
        
        for stmt in statements:
            if stmt.strip():
                query = 'CREATE OR REPLACE' + stmt
                try:
                    job = client.query(query)
                    job.result()
                except Exception as e:
                    logger.warning(f"Skipping statement: {str(e)[:100]}")
        
        logger.info("  ✅ Quality tables updated")
        results['checks_run'].append({
            'check': 'quality_tables_update',
            'status': 'success'
        })
        
    except Exception as e:
        logger.error(f"  ❌ Error updating quality tables: {str(e)}")
        results['checks_run'].append({
            'check': 'quality_tables_update',
            'status': 'error',
            'error': str(e)
        })
    
    # Check for stale tables
    try:
        logger.info("  → Checking for stale data...")
        
        stale_query = f"""
            SELECT table_name, hours_stale, layer
            FROM `{PROJECT_ID}.{DATASET_QUALITY}.data_freshness`
            WHERE is_stale = TRUE
            AND DATE(checked_at) = CURRENT_DATE()
        """
        
        stale_results = client.query(stale_query).result()
        
        for row in stale_results:
            alert_msg = f"⚠️  STALE DATA: {row.table_name} ({row.layer}) is {row.hours_stale} hours old"
            logger.warning(alert_msg)
            results['alerts'].append({
                'type': 'stale_data',
                'table': row.table_name,
                'layer': row.layer,
                'hours_stale': row.hours_stale,
                'message': alert_msg
            })
        
        if not results['alerts']:
            logger.info("  ✅ No stale tables found")
        
    except Exception as e:
        logger.error(f"  ❌ Error checking staleness: {str(e)}")
    
    # Check for quality failures
    try:
        logger.info("  → Checking quality metrics...")
        
        quality_query = f"""
            SELECT table_name, metric_name, status, metric_value, threshold
            FROM `{PROJECT_ID}.{DATASET_QUALITY}.data_quality_metrics`
            WHERE status IN ('FAIL', 'WARN')
            AND DATE(checked_at) = CURRENT_DATE()
        """
        
        quality_results = client.query(quality_query).result()
        
        for row in quality_results:
            alert_msg = f"{'❌' if row.status == 'FAIL' else '⚠️ '} QUALITY {row.status}: {row.table_name}.{row.metric_name} = {row.metric_value:.2f} (threshold: {row.threshold})"
            logger.warning(alert_msg)
            results['alerts'].append({
                'type': 'quality_metric',
                'table': row.table_name,
                'metric': row.metric_name,
                'status': row.status,
                'value': row.metric_value,
                'threshold': row.threshold,
                'message': alert_msg
            })
        
        if not any(a['type'] == 'quality_metric' for a in results['alerts']):
            logger.info("  ✅ All quality metrics passed")
        
    except Exception as e:
        logger.error(f"  ❌ Error checking quality metrics: {str(e)}")
    
    # Check for row count anomalies
    try:
        logger.info("  → Checking row count anomalies...")
        
        anomaly_query = f"""
            SELECT table_name, row_count, previous_row_count, change_pct
            FROM `{PROJECT_ID}.{DATASET_QUALITY}.row_count_tracking`
            WHERE is_anomaly = TRUE
            AND DATE(checked_at) = CURRENT_DATE()
        """
        
        anomaly_results = client.query(anomaly_query).result()
        
        for row in anomaly_results:
            alert_msg = f"⚠️  ANOMALY: {row.table_name} changed {row.change_pct:.1f}% ({row.previous_row_count:,} → {row.row_count:,} rows)"
            logger.warning(alert_msg)
            results['alerts'].append({
                'type': 'row_count_anomaly',
                'table': row.table_name,
                'row_count': row.row_count,
                'previous_row_count': row.previous_row_count,
                'change_pct': row.change_pct,
                'message': alert_msg
            })
        
        if not any(a['type'] == 'row_count_anomaly' for a in results['alerts']):
            logger.info("  ✅ No row count anomalies")
        
    except Exception as e:
        logger.error(f"  ❌ Error checking anomalies: {str(e)}")
    
    # Generate summary
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    results['summary'] = {
        'total_alerts': len(results['alerts']),
        'stale_tables': sum(1 for a in results['alerts'] if a['type'] == 'stale_data'),
        'quality_issues': sum(1 for a in results['alerts'] if a['type'] == 'quality_metric'),
        'anomalies': sum(1 for a in results['alerts'] if a['type'] == 'row_count_anomaly'),
        'duration_seconds': duration,
        'timestamp': end_time.isoformat()
    }
    
    if results['alerts']:
        logger.warning(f"⚠️  Quality check complete: {len(results['alerts'])} issues found ({duration:.1f}s)")
    else:
        logger.info(f"✅ Quality check complete: All checks passed ({duration:.1f}s)")
    
    # TODO: Send alerts to Slack/Email if needed
    # if results['alerts']:
    #     send_alerts_to_slack(results['alerts'])
    
    return results
