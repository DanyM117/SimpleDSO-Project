output "zone_id" {
  description = "ID de la Hosted Zone privada de Route 53"
  value       = aws_route53_zone.private.zone_id
}

output "zone_arn" {
  description = "ARN de la Hosted Zone"
  value       = aws_route53_zone.private.arn
}

output "erp_fqdn" {
  description = "FQDN que debe consumir el agente de IA"
  value       = local.fqdn
}

output "resolved_ip" {
  description = "IP a la que resuelve actualmente el FQDN"
  value       = local.target_ip
}