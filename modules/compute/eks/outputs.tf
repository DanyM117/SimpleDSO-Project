output "cluster-id" { value = module.eks_aws.cluster_id }
output "managed-node-groups" { value = module.eks_aws.eks_managed_node_groups }
output "eks-node-sg-id" { value = module.eks_aws.node_security_group_id }
output "cluster_name" {
  description = "Nombre identificador del cluster EKS"
  value       = module.eks_aws.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del API Server de EKS"
  value       = module.eks_aws.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado CA en base64 para autenticacion TLS de kubectl/helm"
  value       = module.eks_aws.cluster_certificate_authority_data
}

output "eks_node_sg_id" {
  description = "Security Group ID de los nodos de computo"
  value       = module.eks_aws.node_security_group_id
}