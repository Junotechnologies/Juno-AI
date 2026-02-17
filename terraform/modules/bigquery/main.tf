# ========================================
# BIGQUERY DATASETS - MEDALLION ARCHITECTURE
# ========================================

# Bronze Layer - Raw data from Firestore
resource "google_bigquery_dataset" "bronze" {
  project    = var.project_id
  dataset_id = "${var.bronze_dataset_id}_${var.environment}"
  location   = var.location

  friendly_name              = "Bronze Layer - Raw Data (${upper(var.environment)})"
  description                = "Bronze layer containing raw data imported from Firestore"
  delete_contents_on_destroy = !var.delete_protection

  labels = merge(var.labels, {
    layer       = "bronze"
    environment = var.environment
    data_type   = "raw"
  })

  access {
    role          = "OWNER"
    user_by_email = var.service_account_email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
}

# Silver Layer - Curated/cleansed data
resource "google_bigquery_dataset" "silver" {
  project    = var.project_id
  dataset_id = "${var.silver_dataset_id}_${var.environment}"
  location   = var.location

  friendly_name              = "Silver Layer - Curated Data (${upper(var.environment)})"
  description                = "Silver layer containing cleansed, validated, and enriched data"
  delete_contents_on_destroy = !var.delete_protection

  labels = merge(var.labels, {
    layer       = "silver"
    environment = var.environment
    data_type   = "curated"
  })

  access {
    role          = "OWNER"
    user_by_email = var.service_account_email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
}

# Gold Layer - Business-ready analytics data
resource "google_bigquery_dataset" "gold" {
  project    = var.project_id
  dataset_id = "${var.gold_dataset_id}_${var.environment}"
  location   = var.location

  friendly_name              = "Gold Layer - Analytics (${upper(var.environment)})"
  description                = "Gold layer containing aggregated, analytics-ready data for dashboards and ML"
  delete_contents_on_destroy = !var.delete_protection

  labels = merge(var.labels, {
    layer       = "gold"
    environment = var.environment
    data_type   = "analytics"
  })

  access {
    role          = "OWNER"
    user_by_email = var.service_account_email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
}

# Quality Layer - Data quality monitoring
resource "google_bigquery_dataset" "quality" {
  project    = var.project_id
  dataset_id = "${var.quality_dataset_id}_${var.environment}"
  location   = var.location

  friendly_name              = "Quality Layer - Monitoring (${upper(var.environment)})"
  description                = "Quality layer for data quality metrics, validation results, and monitoring"
  delete_contents_on_destroy = !var.delete_protection

  labels = merge(var.labels, {
    layer       = "quality"
    environment = var.environment
    data_type   = "monitoring"
  })

  access {
    role          = "OWNER"
    user_by_email = var.service_account_email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
}
