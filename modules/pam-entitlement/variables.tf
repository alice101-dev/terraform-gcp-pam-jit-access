variable "entitlement_id" {
  description = "Unique ID for the entitlement (4-63 chars, [a-z][0-9]-, starting with a letter). Becomes the last part of the resource name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,62}$", var.entitlement_id))
    error_message = "entitlement_id must be 4-63 chars, lowercase letters/digits/hyphens, and start with a letter."
  }
}

variable "parent" {
  description = "Parent resource: projects/{project-id|number}, folders/{number}, or organizations/{number}."
  type        = string
}

variable "location" {
  description = "Region of the entitlement. PAM entitlements are typically created in 'global'."
  type        = string
  default     = "global"
}

variable "max_request_duration" {
  description = "Maximum grant lifetime in seconds with a trailing 's' (e.g. 4 hours = \"14400s\"). Requesters may ask for less, never more."
  type        = string
  default     = "14400s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.max_request_duration))
    error_message = "max_request_duration must be an integer number of seconds suffixed with 's', e.g. \"14400s\"."
  }
}

variable "eligible_principals" {
  description = "IAM v1 principal identifiers allowed to REQUEST this elevation (e.g. group:sre@example.com, user:alice@example.com)."
  type        = list(string)

  validation {
    condition     = length(var.eligible_principals) > 0
    error_message = "At least one eligible principal is required."
  }
}

variable "resource" {
  description = "Full resource name the grant applies to, e.g. //cloudresourcemanager.googleapis.com/projects/my-project."
  type        = string
}

variable "resource_type" {
  description = "Type of the target resource, e.g. cloudresourcemanager.googleapis.com/Project."
  type        = string
  default     = "cloudresourcemanager.googleapis.com/Project"
}

variable "role_bindings" {
  description = "Roles granted (temporarily) on successful activation, with an optional IAM condition expression."
  type = list(object({
    role                 = string
    condition_expression = optional(string)
  }))
}

variable "requester_justification" {
  description = "Justification requirement: 'unstructured' (free-text required) or 'not_mandatory'."
  type        = string
  default     = "unstructured"

  validation {
    condition     = contains(["unstructured", "not_mandatory"], var.requester_justification)
    error_message = "requester_justification must be either 'unstructured' or 'not_mandatory'."
  }
}

variable "require_approval" {
  description = "Whether a manual approval workflow gates the grant. Strongly recommended for privileged roles."
  type        = bool
  default     = true
}

variable "approvers" {
  description = "IAM v1 principal identifiers who may approve grants. Required when require_approval is true."
  type        = list(string)
  default     = []
}

variable "approvals_needed" {
  description = "Number of distinct approvers required. Currently only 1 is supported by the PAM API."
  type        = number
  default     = 1
}

variable "require_approver_justification" {
  description = "Whether approvers must provide a justification when approving/denying."
  type        = bool
  default     = true
}

variable "approver_email_recipients" {
  description = "Extra e-mail addresses notified when a grant is pending approval."
  type        = list(string)
  default     = []
}

variable "admin_email_recipients" {
  description = "Extra e-mail addresses notified when a requester is granted access."
  type        = list(string)
  default     = []
}

variable "requester_email_recipients" {
  description = "Extra e-mail addresses notified about an eligible entitlement."
  type        = list(string)
  default     = []
}

variable "deletion_policy" {
  description = "Behaviour on destroy: DELETE, ABANDON, or PREVENT."
  type        = string
  default     = "DELETE"

  validation {
    condition     = contains(["DELETE", "ABANDON", "PREVENT"], var.deletion_policy)
    error_message = "deletion_policy must be one of DELETE, ABANDON, or PREVENT."
  }
}
