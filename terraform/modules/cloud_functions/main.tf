# ========================================
# CLOUD FUNCTIONS (GEN 2)
# ========================================

# Refresh Silver Layer Function
resource "google_cloudfunctions2_function" "refresh_silver" {
  project  = var.project_id
  name     = "refresh-silver-${var.environment}"
  location = var.region

  build_config {
    runtime     = var.runtime
    entry_point = "main"

    source {
      storage_source {
        bucket = var.functions_source_bucket
        object = google_storage_bucket_object.refresh_silver_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "${var.memory}M"
    timeout_seconds       = var.timeout
    service_account_email = var.service_account_email

    environment_variables = {
      PROJECT_ID        = var.project_id
      ENVIRONMENT       = var.environment
      BRONZE_DATASET_ID = var.bronze_dataset_id
      SILVER_DATASET_ID = var.silver_dataset_id
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    function    = "refresh-silver"
  })
}

# Refresh Gold Layer Function
resource "google_cloudfunctions2_function" "refresh_gold" {
  project  = var.project_id
  name     = "refresh-gold-${var.environment}"
  location = var.region

  build_config {
    runtime     = var.runtime
    entry_point = "main"

    source {
      storage_source {
        bucket = var.functions_source_bucket
        object = google_storage_bucket_object.refresh_gold_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 5
    min_instance_count    = 0
    available_memory      = "${var.memory}M"
    timeout_seconds       = var.timeout
    service_account_email = var.service_account_email

    environment_variables = {
      PROJECT_ID        = var.project_id
      ENVIRONMENT       = var.environment
      SILVER_DATASET_ID = var.silver_dataset_id
      GOLD_DATASET_ID   = var.gold_dataset_id
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    function    = "refresh-gold"
  })
}

# Quality Check Function
resource "google_cloudfunctions2_function" "quality_check" {
  count = var.enable_quality_checks ? 1 : 0

  project  = var.project_id
  name     = "quality-check-${var.environment}"
  location = var.region

  build_config {
    runtime     = var.runtime
    entry_point = "main"

    source {
      storage_source {
        bucket = var.functions_source_bucket
        object = google_storage_bucket_object.quality_check_source[0].name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "${var.memory}M"
    timeout_seconds       = var.timeout
    service_account_email = var.service_account_email

    environment_variables = {
      PROJECT_ID         = var.project_id
      ENVIRONMENT        = var.environment
      QUALITY_DATASET_ID = var.quality_dataset_id
      BRONZE_DATASET_ID  = var.bronze_dataset_id
      SILVER_DATASET_ID  = var.silver_dataset_id
      GOLD_DATASET_ID    = var.gold_dataset_id
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    function    = "quality-check"
  })
}

# ML Snapshot Function
resource "google_cloudfunctions2_function" "ml_snapshot" {
  count = var.enable_ml_snapshots ? 1 : 0

  project  = var.project_id
  name     = "ml-snapshot-${var.environment}"
  location = var.region

  build_config {
    runtime     = var.runtime
    entry_point = "main"

    source {
      storage_source {
        bucket = var.functions_source_bucket
        object = google_storage_bucket_object.ml_snapshot_source[0].name
      }
    }
  }

  service_config {
    max_instance_count    = 2
    min_instance_count    = 0
    available_memory      = "${var.memory * 2}M" # ML functions need more memory
    timeout_seconds       = var.timeout
    service_account_email = var.service_account_email

    environment_variables = {
      PROJECT_ID      = var.project_id
      ENVIRONMENT     = var.environment
      GOLD_DATASET_ID = var.gold_dataset_id
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    function    = "ml-snapshot"
  })
}

# ========================================
# EXPLICIT INVOKER BINDINGS (GEN 2 / CLOUD RUN)
# ========================================

resource "google_cloud_run_service_iam_member" "refresh_silver_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.refresh_silver.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.invoker_service_account_email}"
}

resource "google_cloud_run_service_iam_member" "refresh_gold_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.refresh_gold.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.invoker_service_account_email}"
}

resource "google_cloud_run_service_iam_member" "quality_check_invoker" {
  count = var.enable_quality_checks ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.quality_check[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.invoker_service_account_email}"
}

resource "google_cloud_run_service_iam_member" "ml_snapshot_invoker" {
  count = var.enable_ml_snapshots ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.ml_snapshot[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.invoker_service_account_email}"
}

# ========================================
# UPLOAD FUNCTION SOURCE CODE TO GCS
# ========================================

# Note: In production, you'd use a CI/CD pipeline to build and upload these
# For now, we'll create placeholder objects that reference the local functions

data "archive_file" "refresh_silver" {
  type        = "zip"
  source_dir  = "${path.root}/../bigquery_medallion_migration/functions/refresh_silver"
  output_path = "${path.root}/.terraform/tmp/refresh_silver.zip"
}

resource "google_storage_bucket_object" "refresh_silver_source" {
  name   = "functions/refresh_silver-${data.archive_file.refresh_silver.output_md5}.zip"
  bucket = var.functions_source_bucket
  source = data.archive_file.refresh_silver.output_path
}

data "archive_file" "refresh_gold" {
  type        = "zip"
  source_dir  = "${path.root}/../bigquery_medallion_migration/functions/refresh_gold"
  output_path = "${path.root}/.terraform/tmp/refresh_gold.zip"
}

resource "google_storage_bucket_object" "refresh_gold_source" {
  name   = "functions/refresh_gold-${data.archive_file.refresh_gold.output_md5}.zip"
  bucket = var.functions_source_bucket
  source = data.archive_file.refresh_gold.output_path
}

data "archive_file" "quality_check" {
  count       = var.enable_quality_checks ? 1 : 0
  type        = "zip"
  source_dir  = "${path.root}/../bigquery_medallion_migration/functions/quality_check"
  output_path = "${path.root}/.terraform/tmp/quality_check.zip"
}

resource "google_storage_bucket_object" "quality_check_source" {
  count  = var.enable_quality_checks ? 1 : 0
  name   = "functions/quality_check-${data.archive_file.quality_check[0].output_md5}.zip"
  bucket = var.functions_source_bucket
  source = data.archive_file.quality_check[0].output_path
}

data "archive_file" "ml_snapshot" {
  count       = var.enable_ml_snapshots ? 1 : 0
  type        = "zip"
  source_dir  = "${path.root}/../bigquery_medallion_migration/functions/create_ml_snapshot"
  output_path = "${path.root}/.terraform/tmp/ml_snapshot.zip"
}

resource "google_storage_bucket_object" "ml_snapshot_source" {
  count  = var.enable_ml_snapshots ? 1 : 0
  name   = "functions/ml_snapshot-${data.archive_file.ml_snapshot[0].output_md5}.zip"
  bucket = var.functions_source_bucket
  source = data.archive_file.ml_snapshot[0].output_path
}

# ========================================
# OPTIONAL PUBLIC INVOCATION
# ========================================

# For public access on Gen2 functions, grant roles/run.invoker on the underlying
# Cloud Run service to allUsers (not recommended for private pipelines).
