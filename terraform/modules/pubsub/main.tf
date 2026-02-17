# ========================================
# PUB/SUB TOPICS
# ========================================

# Topic for data refresh events
resource "google_pubsub_topic" "data_refresh" {
  project = var.project_id
  name    = "data-refresh-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    purpose     = "data-refresh-events"
  })

  message_retention_duration = "86400s" # 24 hours
}

# Topic for data quality events
resource "google_pubsub_topic" "data_quality" {
  project = var.project_id
  name    = "data-quality-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    purpose     = "data-quality-events"
  })

  message_retention_duration = "86400s"
}

# Topic for ML pipeline events
resource "google_pubsub_topic" "ml_pipeline" {
  project = var.project_id
  name    = "ml-pipeline-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    purpose     = "ml-pipeline-events"
  })

  message_retention_duration = "172800s" # 48 hours
}

# ========================================
# PUB/SUB SUBSCRIPTIONS
# ========================================

# Subscription for data refresh events
resource "google_pubsub_subscription" "data_refresh_sub" {
  project = var.project_id
  name    = "data-refresh-sub-${var.environment}"
  topic   = google_pubsub_topic.data_refresh.name

  # Acknowledge deadline
  ack_deadline_seconds = 600

  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # Message retention
  message_retention_duration = "86400s"

  labels = merge(var.labels, {
    environment = var.environment
  })
}

# Subscription for data quality events
resource "google_pubsub_subscription" "data_quality_sub" {
  project = var.project_id
  name    = "data-quality-sub-${var.environment}"
  topic   = google_pubsub_topic.data_quality.name

  ack_deadline_seconds = 300

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "300s"
  }

  message_retention_duration = "86400s"

  labels = merge(var.labels, {
    environment = var.environment
  })
}

# ========================================
# IAM BINDINGS
# ========================================

# Allow service account to publish to topics
resource "google_pubsub_topic_iam_member" "publisher_data_refresh" {
  project = var.project_id
  topic   = google_pubsub_topic.data_refresh.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.service_account_email}"
}

resource "google_pubsub_topic_iam_member" "publisher_data_quality" {
  project = var.project_id
  topic   = google_pubsub_topic.data_quality.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.service_account_email}"
}

resource "google_pubsub_topic_iam_member" "publisher_ml_pipeline" {
  project = var.project_id
  topic   = google_pubsub_topic.ml_pipeline.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.service_account_email}"
}

# Allow service account to subscribe
resource "google_pubsub_subscription_iam_member" "subscriber_data_refresh" {
  project      = var.project_id
  subscription = google_pubsub_subscription.data_refresh_sub.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.service_account_email}"
}

resource "google_pubsub_subscription_iam_member" "subscriber_data_quality" {
  project      = var.project_id
  subscription = google_pubsub_subscription.data_quality_sub.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.service_account_email}"
}
