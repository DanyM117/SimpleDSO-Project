output "eks_cluster_name" {
  description = "Nombre del cluster EKS consumido por addons"
  value       = module.core_eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint de EKS consumido por los proveedores Helm/Kubernetes"
  value       = module.core_eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "CA Certificate consumido por los proveedores Helm/Kubernetes"
  value       = module.core_eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.core_vpc.vpc_id
}

output "private_app_subnet_ids" {
  description = "Subredes privadas de aplicacion"
  value       = module.core_vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Subredes privadas de base de datos"
  value       = module.core_vpc.private_db_subnet_ids
}

output "agent_db_endpoint" {
  description = "Endpoint de conexión para la persistencia del Agente IA"
  value       = module.agent_rds.db_instance_endpoint
}

output "agent_db_address" {
  description = "Host de conexión interna para el Agente IA"
  value       = module.agent_rds.db_instance_address
}

output "agent_db_secret_arn" {
  description = "ARN en Secrets Manager de las credenciales de la base de datos"
  value       = module.agent_rds.master_user_secret_arn
}

output "agent_iam_role_arn" {
  description = "ARN del rol de Pod Identity para el Agente IA"
  value       = module.agent_security.pod_identity_role_arn
}

output "agent_service_account_name" {
  description = "ServiceAccount a vincular en los despliegues del Agente"
  value       = module.agent_security.service_account_name
}