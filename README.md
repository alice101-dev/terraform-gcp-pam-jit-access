# Terraform — GCP Privileged Access Manager (PAM)

Just-in-time (JIT) temporary privilege elevation for select principals on GCP,
plus the audit-logging setup to review every elevation. Built with
[GCP Privileged Access Manager](https://cloud.google.com/iam/docs/pam-overview).

Instead of granting standing admin access, principals request a **time-boxed
grant**. Optionally the request goes through an **approval workflow**, the role
is bound only for the granted window, and it is **revoked automatically** on
expiry. Every request / approval / activation is recorded in Cloud Audit Logs.

## What this provisions

| Entitlement | Sensitive target | Role granted | Window | Approval |
| --- | --- | --- | --- | --- |
| `gke-workload-breakglass` | GKE workloads | `roles/container.admin` | 2h | ✅ |
| `cloudsql-admin-jit` | Cloud SQL | `roles/cloudsql.admin` | 3h | ✅ |
| `memorystore-valkey-jit` | Memorystore for Valkey | `roles/memorystore.admin` | 1h | ✅ |
| `secret-accessor-jit` | Secret Manager | `roles/secretmanager.secretAccessor` | 30m | ✅ |

Plus:

- **Required APIs** enabled (PAM, IAM, and each gated service).
- **PAM IAM roles** — admins (`privilegedaccessmanager.admin`) and viewers.
- **Audit logging** — Data Access logs (`ADMIN_READ` / `DATA_READ` /
  `DATA_WRITE`) enabled on the sensitive services, and auditors granted read
  access. Admin Activity logs (which include all PAM grant/approve/deny events)
  are always on.

## Repository layout

```
.
├── modules/
│   └── pam-entitlement/      # reusable entitlement wrapper
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── resources/                # root config (the deployable stack)
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars      # example values — edit before applying
│   └── backend.tf.example    # GCS remote-state template
├── .gitignore
└── README.md
```

## Prerequisites

- Terraform >= 1.5.0, `hashicorp/google` provider >= 7.0, < 8.0.
- A GCP project and credentials with rights to enable APIs, manage IAM, and
  create PAM entitlements (e.g. `roles/privilegedaccessmanager.admin` +
  `roles/resourcemanager.projectIamAdmin` + `roles/serviceusage.serviceUsageAdmin`).
- The requesting/approving principals should be **groups** (best practice) that
  already exist in Cloud Identity / Workspace.

## Usage

```bash
cd resources

# 1. Edit terraform.tfvars — set project_id and your real groups/emails.
# 2. (Optional) Enable remote state:
cp backend.tf.example backend.tf   # then edit the bucket name

terraform init
terraform plan
terraform apply
```

## The JIT flow (day-2)

1. A principal opens **IAM & Admin → Privileged Access Manager → Grants →
   Request grant**, picks an entitlement, duration, and justification.
   (CLI: `gcloud pam grants create ...`.)
2. If approval is required, an approver approves/denies
   (`gcloud pam grants approve ...`).
3. On approval the role is bound for the requested duration and revoked at
   expiry — no manual cleanup.

## Reviewing audit logs

All PAM activity lands in Cloud Audit Logs. Example queries in **Logs Explorer**:

```
# Every PAM entitlement/grant action
protoPayload.serviceName="privilegedaccessmanager.googleapis.com"

# Grants that were activated (access actually granted)
protoPayload.serviceName="privilegedaccessmanager.googleapis.com"
protoPayload.methodName:"CreateGrant"

# What an elevated principal did on Cloud SQL afterwards (Data Access logs)
protoPayload.serviceName="cloudsql.googleapis.com"
protoPayload.authenticationInfo.principalEmail="alice@example.com"
```

CLI equivalent:

```bash
gcloud logging read \
  'protoPayload.serviceName="privilegedaccessmanager.googleapis.com"' \
  --project my-production-project --limit 50
```

## Production notes

- **Least privilege & short windows.** Durations are intentionally tight; a
  requester can always ask for less. Prefer scoping `role_bindings` with a
  `condition_expression` to narrow the blast radius further.
- **Approval on everything privileged.** Every entitlement here requires manual
  approval by a separate group (separation of duties). The PAM API currently
  supports `approvals_needed = 1`.
- **Groups, not users.** `eligible_principals` and `approvers` should be groups
  so membership changes don't require a Terraform apply.
- **Remote state.** Use the GCS backend with versioning + locking; never commit
  `*.tfstate`.
- **Data Access logs cost money.** They are enabled here for the gated services;
  scope `audited_services` to what you actually need to review.
