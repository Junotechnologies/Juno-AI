# ========================================
# CLOUD SCHEDULER JOBS
# ========================================

# Refresh Silver Layer - Daily at 2 AM
resource "google_cloud_scheduler_job" "refresh_silver" {
  project   = var.project_id
  region    = var.region
  name      = "refresh-silver-${var.environment}"
  schedule  = var.refresh_silver_cron
  time_zone = var.timezone

  http_target {
    http_method = "POST"
    uri         = var.refresh_silver_url

    oidc_token {
      service_account_email = var.service_account_email
      audience              = trimsuffix(var.refresh_silver_url, "/")
    }
  }

  retry_config {
    retry_count = 3
  }
}

# Refresh Gold Layer - Weekly on Sunday at 3 AM
resource "google_cloud_scheduler_job" "refresh_gold" {
  project   = var.project_id
  region    = var.region
  name      = "refresh-gold-${var.environment}"
  schedule  = var.refresh_gold_cron
  time_zone = var.timezone

  http_target {
    http_method = "POST"
    uri         = var.refresh_gold_url

    oidc_token {
      service_account_email = var.service_account_email
      audience              = trimsuffix(var.refresh_gold_url, "/")
    }
  }

  retry_config {
    retry_count = 3
  }
}

# Quality Check - Hourly
resource "google_cloud_scheduler_job" "quality_check" {
  count = var.enable_quality_checks ? 1 : 0

  project   = var.project_id
  region    = var.region
  name      = "quality-check-${var.environment}"
  schedule  = var.quality_check_cron
  time_zone = var.timezone

  http_target {
    http_method = "POST"
    uri         = var.quality_check_url

    oidc_token {
      service_account_email = var.service_account_email
      audience              = trimsuffix(var.quality_check_url, "/")
    }
  }

  retry_config {
    retry_count = 2
  }
}

# ML Snapshot - Weekly on Monday at 4 AM
resource "google_cloud_scheduler_job" "ml_snapshot" {
  count = var.enable_ml_snapshots ? 1 : 0

  project   = var.project_id
  region    = var.region
  name      = "ml-snapshot-${var.environment}"
  schedule  = var.ml_snapshot_cron
  time_zone = var.timezone

  http_target {
    http_method = "POST"
    uri         = var.ml_snapshot_url

    oidc_token {
      service_account_email = var.service_account_email
      audience              = trimsuffix(var.ml_snapshot_url, "/")
    }
  }

  retry_config {
    retry_count = 3
  }
}
