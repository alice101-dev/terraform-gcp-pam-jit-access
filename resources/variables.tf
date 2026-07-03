variable "project_id" {
  description = "The GCP project ID that hosts the PAM entitlements and the gated resources."
  type        = string
}

variable "region" {
  description = "Default provider region for the project."
  type        = string
  default     = "asia-southeast2"
}

variable "location" {
  description = "Location for the PAM entitlements. PAM entitlements are created in 'global'."
  type        = string
  default     = "global"
}

variable "entitlements" {
  description = <<-EOT
    Map of PAM entitlements to create. The map key becomes the entitlement_id.
    Each value describes who may request which roles, for how long, and whether
    approval is required.
  EOT
  type = map(object({
    max_request_duration = string
    eligible_principals  = list(string)
    role_bindings = list(object({
      role                 = string
      condition_expression = optional(string)
    }))
    requester_justification = optional(string, "unstructured")
    require_approval        = optional(bool, true)
    approvers               = optional(list(string), [])
  }))
}

variable "security_notification_emails" {
  description = "E-mail addresses notified about grant activity and pending approvals."
  type        = list(string)
  default     = []
}

variable "pam_admin_principals" {
  description = "Principals granted roles/privilegedaccessmanager.admin (manage entitlements)."
  type        = list(string)
  default     = []
}

variable "pam_viewer_principals" {
  description = "Principals granted roles/privilegedaccessmanager.viewer (read entitlements/grants)."
  type        = list(string)
  default     = []
}

variable "audited_services" {
  description = "Services for which Data Access audit logs (ADMIN_READ/DATA_READ/DATA_WRITE) are enabled."
  type        = list(string)
  default = [
    "cloudsql.googleapis.com",
    "container.googleapis.com",
    "memorystore.googleapis.com",
    "secretmanager.googleapis.com",
  ]
}

variable "auditor_principals" {
  description = "Principals granted read access to audit logs (logging.viewer + privateLogViewer)."
  type        = list(string)
  default     = []
}
