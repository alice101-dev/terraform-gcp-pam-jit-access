# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------
locals {
  parent   = "projects/${var.project_id}"
  resource = "//cloudresourcemanager.googleapis.com/projects/${var.project_id}"

  # APIs that must be enabled for PAM and for the sensitive services it gates.
  required_services = [
    "privilegedaccessmanager.googleapis.com", # PAM control plane
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",   # GKE workloads
    "sqladmin.googleapis.com",    # Cloud SQL
    "memorystore.googleapis.com", # Memorystore for Valkey
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
  ]
}

# ---------------------------------------------------------------------------
# Enable required APIs
# ---------------------------------------------------------------------------
resource "google_project_service" "required" {
  for_each = toset(local.required_services)

  project = var.project_id
  service = each.value

  # Keep APIs enabled even if this config is destroyed — other workloads rely on them.
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# PAM Entitlements (just-in-time elevation)
#
# Each entry in var.entitlements produces one entitlement. Common approval and
# notification defaults live here so that the tfvars stay focused on intent
# (who, which role, how long).
# ---------------------------------------------------------------------------
module "entitlements" {
  source   = "../modules/pam-entitlement"
  for_each = var.entitlements

  entitlement_id       = each.key
  parent               = local.parent
  location             = var.location
  resource             = local.resource
  resource_type        = "cloudresourcemanager.googleapis.com/Project"
  max_request_duration = each.value.max_request_duration

  eligible_principals = each.value.eligible_principals
  role_bindings       = each.value.role_bindings

  requester_justification = each.value.requester_justification

  require_approval               = each.value.require_approval
  approvers                      = each.value.approvers
  require_approver_justification = true

  # Route all administrative notifications to the security mailing list.
  admin_email_recipients    = var.security_notification_emails
  approver_email_recipients = var.security_notification_emails

  depends_on = [google_project_service.required]
}

# ---------------------------------------------------------------------------
# Access to view / operate PAM
#
# PAM itself is administered through IAM. Grant break-glass administrators the
# ability to manage entitlements, and auditors read-only visibility.
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "pam_admins" {
  for_each = toset(var.pam_admin_principals)

  project = var.project_id
  role    = "roles/privilegedaccessmanager.admin"
  member  = each.value
}

resource "google_project_iam_member" "pam_viewers" {
  for_each = toset(var.pam_viewer_principals)

  project = var.project_id
  role    = "roles/privilegedaccessmanager.viewer"
  member  = each.value
}

# ---------------------------------------------------------------------------
# Audit logging
#
# 1. Data Access audit logs for the sensitive services are OFF by default in
#    GCP. Enable them so every read/write against the gated resources is
#    recorded (Admin Activity logs — including all PAM grant/approve/deny
#    actions — are always on and cannot be disabled).
# 2. Grant auditors read access to those logs.
# ---------------------------------------------------------------------------
resource "google_project_iam_audit_config" "data_access" {
  for_each = toset(var.audited_services)

  project = var.project_id
  service = each.value

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_project_iam_member" "auditors_log_viewer" {
  for_each = toset(var.auditor_principals)

  project = var.project_id
  role    = "roles/logging.viewer"
  member  = each.value
}

# Data Access logs are surfaced through the Private Logs Viewer role.
resource "google_project_iam_member" "auditors_private_log_viewer" {
  for_each = toset(var.auditor_principals)

  project = var.project_id
  role    = "roles/logging.privateLogViewer"
  member  = each.value
}
