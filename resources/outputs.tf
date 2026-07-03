output "entitlement_ids" {
  description = "Map of entitlement key => fully qualified entitlement ID."
  value       = { for k, m in module.entitlements : k => m.id }
}

output "entitlement_names" {
  description = "Map of entitlement key => output-only hierarchical name."
  value       = { for k, m in module.entitlements : k => m.name }
}

output "entitlement_states" {
  description = "Map of entitlement key => current state."
  value       = { for k, m in module.entitlements : k => m.state }
}

output "audited_services" {
  description = "Services with Data Access audit logging enabled."
  value       = var.audited_services
}
