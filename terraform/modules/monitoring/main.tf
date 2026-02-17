# ========================================
# MONITORING & ALERTING
# ========================================

# Alert policy for Gen2 function failures (Cloud Run 5xx responses)
resource "google_monitoring_alert_policy" "function_failures" {
  project      = var.project_id
  display_name = "Cloud Function Failures - ${upper(var.environment)}"
  combiner     = "OR"

  conditions {
    display_name = "Gen2 Function 5xx Error Rate"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.label.response_code_class = \"5xx\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  }

  notification_channels = var.notification_email_secret != null ? [google_monitoring_notification_channel.email[0].id] : []

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  enabled = true
}

# Alert policy for BigQuery job failures
# DISABLED: Metric not yet available or may need time to populate
# resource "google_monitoring_alert_policy" "bigquery_failures" {
#   project      = var.project_id
#   display_name = "BigQuery Job Failures - ${upper(var.environment)}"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "BigQuery Job Error Rate"
#
#     condition_threshold {
#       filter          = "resource.type = \"bigquery_project\" AND metric.type = \"bigquery.googleapis.com/job/num_failed_jobs\""
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 3
#
#       aggregations {
#         alignment_period   = "300s"
#         per_series_aligner = "ALIGN_RATE"
#       }
#     }
#   }
#
#   notification_channels = var.notification_email_secret != null ? [google_monitoring_notification_channel.email[0].id] : []
#
#   alert_strategy {
#     auto_close = "604800s"
#   }
#
#   enabled = true
# }

# Alert policy for Gen2 function latency
resource "google_monitoring_alert_policy" "function_duration" {
  project      = var.project_id
  display_name = "Cloud Function Long Execution - ${upper(var.environment)}"
  combiner     = "OR"

  conditions {
    display_name = "Function P95 Latency > 5 minutes"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 300000 # 5 minutes in milliseconds

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  }

  notification_channels = var.notification_email_secret != null ? [google_monitoring_notification_channel.email[0].id] : []

  alert_strategy {
    auto_close = "604800s"
  }

  enabled = true
}

# ========================================
# NOTIFICATION CHANNELS
# ========================================

# Email notification channel (only if email is provided)
resource "google_monitoring_notification_channel" "email" {
  count = var.notification_email_secret != null ? 1 : 0

  project      = var.project_id
  display_name = "Email Notification - ${upper(var.environment)}"
  type         = "email"

  labels = {
    email_address = var.notification_email_secret
  }

  enabled = true
}

# ========================================
# UPTIME CHECKS (OPTIONAL)  
# ========================================

# Example uptime check for a Cloud Function
# Uncomment and modify as needed
# resource "google_monitoring_uptime_check_config" "function_uptime" {
#   display_name = "Cloud Function Uptime - ${var.environment}"
#   timeout      = "10s"
#   period       = "300s"
#
#   http_check {
#     path         = "/"
#     port         = 443
#     use_ssl      = true
#     validate_ssl = true
#   }
#
#   monitored_resource {
#     type = "uptime_url"
#     labels = {
#       project_id = var.project_id
#       host       = "FUNCTION_URL_HERE"
#     }
#   }
# }
