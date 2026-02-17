# ========================================
# SERVICE ACCOUNT FOR CLOUD FUNCTIONS
# ========================================

resource "google_service_account" "cloud_functions_sa" {
  project      = var.project_id
  account_id   = "juno-analytics-${var.environment}-sa"
  display_name = "Juno Analytics Cloud Functions Service Account (${upper(var.environment)})"
  description  = "Service account for Cloud Functions in ${var.environment} environment"
}

# ========================================
# IAM ROLE BINDINGS
# ========================================

resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.service_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
}
