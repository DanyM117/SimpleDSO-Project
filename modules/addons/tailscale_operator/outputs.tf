output "namespace" {
  description = "Namespace donde opera el controlador"
  value       = kubernetes_namespace_v1.tailscale.metadata[0].name
}

output "release_status" {
  description = "Estado del release de Helm"
  value       = helm_release.tailscale_operator.status
}