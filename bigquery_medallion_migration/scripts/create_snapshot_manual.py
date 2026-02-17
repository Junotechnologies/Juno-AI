#!/usr/bin/env python3
"""
Manual ML Snapshot Creation Script
Use this when you need to create a snapshot outside the weekly schedule
(e.g., before training an important model)

Usage:
    python scripts/create_snapshot_manual.py
    python scripts/create_snapshot_manual.py --name snapshot_custom_name
"""

import argparse
from google.cloud import bigquery
from datetime import datetime

def create_snapshot(snapshot_name=None):
    """Create a snapshot of ml_training_base_v2"""
    
    client = bigquery.Client()
    project = "junoplus-dev"
    dataset = "junoplus_analytics_gold"
    
    # Generate snapshot name if not provided
    if not snapshot_name:
        snapshot_name = f"snapshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    snapshot_table = f"ml_snapshot_{snapshot_name}"
    
    print(f"📸 Creating snapshot: {snapshot_name}")
    print(f"   Table: {snapshot_table}")
    print()
    
    # 1. Create snapshot table
    print("1️⃣  Creating snapshot table...")
    snapshot_query = f"""
    CREATE TABLE `{project}.{dataset}.{snapshot_table}`
    PARTITION BY session_date
    CLUSTER BY user_id
    AS
    SELECT
      '{snapshot_name}' as snapshot_id,
      CURRENT_TIMESTAMP() as snapshot_created_at,
      *
    FROM `{project}.{dataset}.ml_training_base_v2`
    """
    
    job = client.query(snapshot_query)
    job.result()  # Wait for completion
    
    # Get table info
    table_ref = client.get_table(f"{project}.{dataset}.{snapshot_table}")
    row_count = table_ref.num_rows
    size_mb = table_ref.num_bytes / (1024 * 1024)
    
    print(f"   ✅ Table created")
    print(f"   Rows: {row_count:,}")
    print(f"   Size: {size_mb:.2f} MB")
    print()
    
    # 2. Register in dataset_registry
    print("2️⃣  Registering snapshot metadata...")
    registry_query = f"""
    INSERT INTO `{project}.{dataset}.dataset_registry`
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
      'manual' as creation_method,
      'v2' as schema_version
    FROM `{project}.{dataset}.{snapshot_table}`
    WHERE snapshot_id = '{snapshot_name}'
    """
    
    client.query(registry_query).result()
    print(f"   ✅ Registered in dataset_registry")
    print()
    
    # 3. Get final statistics
    stats_query = f"""
    SELECT *
    FROM `{project}.{dataset}.dataset_registry`
    WHERE snapshot_id = '{snapshot_name}'
    """
    stats = client.query(stats_query).to_dataframe().iloc[0]
    
    # Print summary
    print("=" * 60)
    print("📊 SNAPSHOT SUMMARY")
    print("=" * 60)
    print(f"Snapshot ID:       {snapshot_name}")
    print(f"Table Name:        {snapshot_table}")
    print(f"Rows:              {stats['row_count']:,}")
    print(f"Date Range:        {stats['date_range_start']} to {stats['date_range_end']}")
    print(f"Unique Users:      {stats['unique_users']}")
    print(f"With Feedback:     {stats['sessions_with_feedback']:,}")
    print(f"Creation Method:   {stats['creation_method']}")
    print(f"Schema Version:    {stats['schema_version']}")
    print(f"Created At:        {stats['created_at']}")
    print("=" * 60)
    print()
    print("🔍 Query this snapshot:")
    print(f"   SELECT * FROM `{project}.{dataset}.{snapshot_table}`")
    print()
    print("✅ Snapshot created successfully!")
    
    return snapshot_name, stats

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Create ML dataset snapshot manually'
    )
    parser.add_argument(
        '--name',
        type=str,
        help='Custom snapshot name (optional, auto-generated if not provided)'
    )
    
    args = parser.parse_args()
    create_snapshot(args.name)
