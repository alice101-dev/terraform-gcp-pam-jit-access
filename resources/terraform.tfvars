project_id = "my-production-project"
region     = "asia-southeast2"
location   = "global"

# Where grant/approval notifications go.
security_notification_emails = [
  "security-oncall@example.com",
]

# Who can administer / view PAM itself.
pam_admin_principals = [
  "group:platform-admins@example.com",
]
pam_viewer_principals = [
  "group:security-auditors@example.com",
]

# Who can read the audit logs.
auditor_principals = [
  "group:security-auditors@example.com",
]

# ---------------------------------------------------------------------------
# Just-in-time entitlements for sensitive services.
# The map key is the entitlement_id.
# ---------------------------------------------------------------------------
entitlements = {
  # GKE workload break-glass: elevate to cluster admin for incident response.
  "gke-workload-breakglass" = {
    max_request_duration = "7200s" # 2 hours
    eligible_principals = [
      "group:sre@example.com",
    ]
    role_bindings = [
      { role = "roles/container.admin" },
    ]
    require_approval = true
    approvers = [
      "group:platform-leads@example.com",
    ]
  }

  # Cloud SQL admin: time-boxed DBA access for schema/maintenance operations.
  "cloudsql-admin-jit" = {
    max_request_duration = "10800s" # 3 hours
    eligible_principals = [
      "group:dba@example.com",
    ]
    role_bindings = [
      { role = "roles/cloudsql.admin" },
    ]
    require_approval = true
    approvers = [
      "group:platform-leads@example.com",
    ]
  }

  # Memorystore for Valkey: elevate to manage/flush cache instances.
  "memorystore-valkey-jit" = {
    max_request_duration = "3600s" # 1 hour
    eligible_principals = [
      "group:sre@example.com",
    ]
    role_bindings = [
      { role = "roles/memorystore.admin" },
    ]
    require_approval = true
    approvers = [
      "group:platform-leads@example.com",
    ]
  }

  # Secret Manager: read sensitive secrets during an incident, low blast radius,
  # short window, still gated by approval.
  "secret-accessor-jit" = {
    max_request_duration = "1800s" # 30 minutes
    eligible_principals = [
      "group:sre@example.com",
      "group:oncall@example.com",
    ]
    role_bindings = [
      { role = "roles/secretmanager.secretAccessor" },
    ]
    require_approval = true
    approvers = [
      "group:security-oncall@example.com",
    ]
  }
}
