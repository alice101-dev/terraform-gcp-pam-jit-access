output "id" {
  description = "Fully qualified entitlement ID: {parent}/locations/{location}/entitlements/{entitlement_id}."
  value       = google_privileged_access_manager_entitlement.this.id
}

output "name" {
  description = "Output-only hierarchical name of the entitlement."
  value       = google_privileged_access_manager_entitlement.this.name
}

output "state" {
  description = "Current state of the entitlement (e.g. AVAILABLE)."
  value       = google_privileged_access_manager_entitlement.this.state
}

output "entitlement_id" {
  description = "The short entitlement ID."
  value       = google_privileged_access_manager_entitlement.this.entitlement_id
}
