locals {
  # Deducción de la IP de destino
  target_ip = (
    var.erp_target == "cloud"     ? var.cloud_private_ip :
    var.erp_target == "onpremise" ? var.onprem_ip : ""
  )

  create_record = var.erp_target != "none" && local.target_ip != ""

  # FQDN resultante
  record_key = var.record_name != "" ? var.record_name : "@"
}

module "route53" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.5.1"

  name    = var.domain_name
  comment = "Private hosted zone para enrutamiento híbrido ERPNext"

  # Conversión a Private Hosted Zone asociada a la VPC
  vpc = {
    core_vpc = {
      vpc_id     = var.vpc_id
      vpc_region = var.aws_region
    }
  }

  # Inyección condicional del registro A dentro del módulo oficial
  records = local.create_record ? {
    (local.record_key) = {
      type    = "A"
      ttl     = var.ttl
      records = [local.target_ip]
    }
  } : {}

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}