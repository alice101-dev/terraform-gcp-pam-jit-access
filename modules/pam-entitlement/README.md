# Module: `pam-entitlement`

Reusable wrapper around
[`google_privileged_access_manager_entitlement`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privileged_access_manager_entitlement).

An **entitlement** is the core PAM object. It declares:

| Question | Field |
| --- | --- |
| **Who** may request elevation? | `eligible_principals` |
| **Which** roles are granted? | `role_bindings` |
| **On what** resource? | `resource` / `resource_type` |
| **For how long?** | `max_request_duration` |
| **With what approval?** | `require_approval` + `approvers` |
| **With what justification?** | `requester_justification` |

Principals never hold standing access — they request a time-boxed **grant**,
optionally pass an approval workflow, receive the role for the granted window,
and the binding is revoked automatically on expiry.

## Usage

```hcl
module "cloudsql_admin_jit" {
  source = "../modules/pam-entitlement"

  entitlement_id       = "cloudsql-admin-jit"
  parent               = "projects/my-project"
  resource             = "//cloudresourcemanager.googleapis.com/projects/my-project"
  resource_type        = "cloudresourcemanager.googleapis.com/Project"
  max_request_duration = "7200s" # 2 hours

  eligible_principals = ["group:dba@example.com"]

  role_bindings = [
    { role = "roles/cloudsql.admin" },
  ]

  require_approval = true
  approvers        = ["group:platform-leads@example.com"]

  admin_email_recipients = ["security@example.com"]
}
```

## Inputs

| Name | Type | Default | Required |
| --- | --- | --- | :---: |
| `entitlement_id` | `string` | – | yes |
| `parent` | `string` | – | yes |
| `resource` | `string` | – | yes |
| `role_bindings` | `list(object({role, condition_expression?}))` | – | yes |
| `eligible_principals` | `list(string)` | – | yes |
| `location` | `string` | `"global"` | no |
| `resource_type` | `string` | `"cloudresourcemanager.googleapis.com/Project"` | no |
| `max_request_duration` | `string` | `"14400s"` | no |
| `requester_justification` | `string` | `"unstructured"` | no |
| `require_approval` | `bool` | `true` | no |
| `approvers` | `list(string)` | `[]` | no |
| `approvals_needed` | `number` | `1` | no |
| `require_approver_justification` | `bool` | `true` | no |
| `approver_email_recipients` | `list(string)` | `[]` | no |
| `admin_email_recipients` | `list(string)` | `[]` | no |
| `requester_email_recipients` | `list(string)` | `[]` | no |
| `deletion_policy` | `string` | `"DELETE"` | no |

## Outputs

| Name | Description |
| --- | --- |
| `id` | Fully qualified entitlement ID |
| `name` | Output-only hierarchical name |
| `state` | Current state of the entitlement |
| `entitlement_id` | Short entitlement ID |
