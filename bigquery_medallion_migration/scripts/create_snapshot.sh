#!/bin/bash
# Simple snapshot creation using bq command
# No Python dependencies needed

PROJECT="junoplus-dev"
DATASET="junoplus_analytics_gold"
SNAPSHOT_NAME="snapshot_$(date +%Y%m%d)"
SNAPSHOT_TABLE="ml_snapshot_${SNAPSHOT_NAME}"

echo "📸 Creating ML snapshot: $SNAPSHOT_NAME"
echo "   Table: $SNAPSHOT_TABLE"
echo ""

# 1. Create snapshot table
echo "1️⃣  Creating snapshot table..."
bq query --use_legacy_sql=false --project_id=$PROJECT <<EOF
CREATE TABLE \`${PROJECT}.${DATASET}.${SNAPSHOT_TABLE}\`
PARTITION BY session_date
CLUSTER BY user_id
AS
SELECT
  '${SNAPSHOT_NAME}' as snapshot_id,
  CURRENT_TIMESTAMP() as snapshot_created_at,
  *
FROM \`${PROJECT}.${DATASET}.ml_training_base_v2\`
EOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to create snapshot table"
    exit 1
fi

echo "   ✅ Snapshot table created"
echo ""

# 2. Register in dataset_registry
echo "2️⃣  Registering snapshot metadata..."
bq query --use_legacy_sql=false --project_id=$PROJECT <<EOF
INSERT INTO \`${PROJECT}.${DATASET}.dataset_registry\`
(snapshot_id, created_at, row_count, date_range_start, date_range_end,
 unique_users, sessions_with_feedback, creation_method, schema_version)
SELECT
  '${SNAPSHOT_NAME}' as snapshot_id,
  CURRENT_TIMESTAMP() as created_at,
  COUNT(*) as row_count,
  MIN(session_date) as date_range_start,
  MAX(session_date) as date_range_end,
  COUNT(DISTINCT user_id) as unique_users,
  COUNTIF(pain_reduction IS NOT NULL) as sessions_with_feedback,
  'manual_bash' as creation_method,
  'v2' as schema_version
FROM \`${PROJECT}.${DATASET}.${SNAPSHOT_TABLE}\`
WHERE snapshot_id = '${SNAPSHOT_NAME}'
EOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to register snapshot"
    exit 1
fi

echo "   ✅ Registered in dataset_registry"
echo ""

# 3. Display summary
echo "=" "========================================================"
echo "📊 SNAPSHOT SUMMARY"
echo "==========================================================="

bq query --use_legacy_sql=false --project_id=$PROJECT --format=pretty <<EOF
SELECT
  snapshot_id,
  row_count,
  date_range_start,
  date_range_end,
  unique_users,
  sessions_with_feedback,
  creation_method,
  CAST(created_at AS STRING) as created_at
FROM \`${PROJECT}.${DATASET}.dataset_registry\`
WHERE snapshot_id = '${SNAPSHOT_NAME}'
EOF

echo ""
echo "🔍 Query this snapshot:"
echo "   SELECT * FROM \`${PROJECT}.${DATASET}.${SNAPSHOT_TABLE}\`"
echo ""
echo "✅ Snapshot created successfully!"
