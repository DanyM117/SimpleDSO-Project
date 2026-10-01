output "namespace" {
  description = "Namespace del External Secrets Operator"
  value       = kubernetes_namespace_v1.external_secrets.metadata[0].name
}

output "release_status" {
  description = "Estado del release de Helm"
  value       = helm_release.external_secrets.status
}