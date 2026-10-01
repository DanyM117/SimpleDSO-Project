output "pod_identity_role_arn" {
  description = "ARN del rol IAM asumido por el pod del Agente IA"
  value       = aws_iam_role.agent_pod_identity.arn
}

output "pod_identity_role_name" {
  description = "Nombre del rol IAM"
  value       = aws_iam_role.agent_pod_identity.name
}

output "association_id" {
  description = "ID de la asociación Pod Identity en EKS"
  value       = aws_eks_pod_identity_association.agent_association.id
}

output "service_account_name" {
  description = "Nombre del ServiceAccount que debe declararse en los manifiestos de Kubernetes"
  value       = var.service_account_name
}