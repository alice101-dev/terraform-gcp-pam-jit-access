# ---------------------------------------------------------------------------
# PAM Entitlement
#
# Wraps google_privileged_access_manager_entitlement so that a single, opinionated
# module can be reused to gate access to any sensitive GCP resource
# (GKE workloads, Cloud SQL, Memorystore Valkey, Secret Manager, ...).
#
# An Entitlement defines WHO (eligible_users) may request WHICH roles
# (privileged_access.gcp_iam_access.role_bindings) on WHAT resource, for HOW
# long (max_request_duration), and under WHICH approval workflow.
# ---------------------------------------------------------------------------

resource "google_privileged_access_manager_entitlement" "this" {
  entitlement_id       = var.entitlement_id
  location             = var.location
  parent               = var.parent
  max_request_duration = var.max_request_duration
  deletion_policy      = var.deletion_policy

  # Principals allowed to REQUEST this elevation (never granted standing access).
  eligible_users {
    principals = var.eligible_principals
  }

  # The roles that are temporarily bound on the target resource once a grant is
  # activated. Roles are revoked automatically when the grant expires.
  privileged_access {
    gcp_iam_access {
      resource      = var.resource
      resource_type = var.resource_type

      dynamic "role_bindings" {
        for_each = var.role_bindings
        content {
          role                 = role_bindings.value.role
          condition_expression = role_bindings.value.condition_expression
        }
      }
    }
  }

  # How the requester must justify the request. Exactly one of the blocks below
  # is emitted based on var.requester_justification.
  requester_justification_config {
    dynamic "unstructured" {
      for_each = var.requester_justification == "unstructured" ? [1] : []
      content {}
    }
    dynamic "not_mandatory" {
      for_each = var.requester_justification == "not_mandatory" ? [1] : []
      content {}
    }
  }

  # Optional manual approval workflow. Omitting this block grants access
  # immediately on request, which is only appropriate for low-risk entitlements.
  dynamic "approval_workflow" {
    for_each = var.require_approval ? [1] : []
    content {
      manual_approvals {
        require_approver_justification = var.require_approver_justification
        steps {
          approvals_needed          = var.approvals_needed
          approver_email_recipients = var.approver_email_recipients
          approvers {
            principals = var.approvers
          }
        }
      }
    }
  }

  # Extra e-mail notifications for admins/requesters, on top of the default
  # per-principal notifications PAM already sends.
  dynamic "additional_notification_targets" {
    for_each = (length(var.admin_email_recipients) > 0 || length(var.requester_email_recipients) > 0) ? [1] : []
    content {
      admin_email_recipients     = var.admin_email_recipients
      requester_email_recipients = var.requester_email_recipients
    }
  }

  # Fail fast on misconfiguration rather than letting the API reject the apply.
  lifecycle {
    precondition {
      condition     = length(var.role_bindings) > 0
      error_message = "At least one role_binding is required for entitlement ${var.entitlement_id}."
    }
    precondition {
      condition     = !var.require_approval || length(var.approvers) > 0
      error_message = "require_approval is true for ${var.entitlement_id} but no approvers were provided."
    }
  }
}
