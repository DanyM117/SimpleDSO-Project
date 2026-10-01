output "zone_id" {
  description = "ID de la Hosted Zone privada de Route 53"
  value       = module.route53.zone_id
}

output "zone_arn" {
  description = "ARN de la Hosted Zone"
  value       = module.route53.zone_arn
}

output "erp_fqdn" {
  description = "FQDN que debe consumir el agente de IA"
  value       = var.record_name != "" ? "${var.record_name}.${var.domain_name}" : var.domain_name
}

output "resolved_ip" {
  description = "IP a la que resuelve actualmente el FQDN"
  value       = local.target_ip
}