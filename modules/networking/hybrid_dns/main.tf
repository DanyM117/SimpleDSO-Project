locals {
  target_ip = (
    var.erp_target == "cloud"     ? var.cloud_private_ip :
    var.erp_target == "onpremise" ? var.onprem_ip : ""
  )

  create_record = var.erp_target != "none" && local.target_ip != ""
  fqdn          = var.record_name != "" ? "${var.record_name}.${var.domain_name}" : var.domain_name
}

# Zona Privada en Route 53
resource "aws_route53_zone" "private" {
  name    = var.domain_name
  comment = "Private hosted zone para enrutamiento hibrido ERPNext"

  vpc {
    vpc_id     = var.vpc_id
    vpc_region = var.aws_region
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Registro A Condicional
resource "aws_route53_record" "erp_endpoint" {
  count = local.create_record ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = local.fqdn
  type    = "A"
  ttl     = var.ttl
  records = [local.target_ip]
}