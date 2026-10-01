output "tailscale_namespace" {
  description = "Namespace donde opera Tailscale Operator"
  value       = module.tailscale_operator.namespace
}

output "tailscale_release_status" {
  description = "Estado del release de Tailscale en Helm"
  value       = module.tailscale_operator.release_status
}

output "eso_namespace" {
  description = "Namespace donde opera External Secrets Operator"
  value       = module.external_secrets.namespace
}

output "eso_release_status" {
  description = "Estado del release de ESO en Helm"
  value       = module.external_secrets.release_status
}