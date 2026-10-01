output "instance_id" {
  description = "ID de la instancia EC2 de ERPNext"
  value       = module.ec2_erp.id
}

output "private_ip" {
  description = "IP privada en la VPC requerida por hybrid_dns"
  value       = module.ec2_erp.private_ip
}