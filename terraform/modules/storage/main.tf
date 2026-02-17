# ========================================
# CLOUD STORAGE BUCKETS
# ========================================

# Bucket for Cloud Functions source code
resource "google_storage_bucket" "functions_source" {
  project       = var.project_id
  name          = "${var.project_id}-functions-source-${var.environment}"
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    purpose     = "cloud-functions-source"
  })
}

# Bucket for staging and temporary files
resource "google_storage_bucket" "staging" {
  project       = var.project_id
  name          = "${var.project_id}-staging-${var.environment}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7 # Delete files older than 7 days
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    purpose     = "staging-temporary"
  })
}

# Bucket for ML model artifacts and snapshots
resource "google_storage_bucket" "ml_artifacts" {
  project       = var.project_id
  name          = "${var.project_id}-ml-artifacts-${var.environment}"
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    purpose     = "ml-artifacts"
  })
}

# ========================================
# IAM BINDINGS FOR BUCKETS
# ========================================

# Allow service account to read/write to functions source bucket
resource "google_storage_bucket_iam_member" "functions_source_admin" {
  bucket = google_storage_bucket.functions_source.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

# Allow service account to read/write to staging bucket
resource "google_storage_bucket_iam_member" "staging_admin" {
  bucket = google_storage_bucket.staging.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

# Allow service account to read/write to ML artifacts bucket
resource "google_storage_bucket_iam_member" "ml_artifacts_admin" {
  bucket = google_storage_bucket.ml_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}
