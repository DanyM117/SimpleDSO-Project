data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket         = var.state_bucket_name
    key            = "dev/core/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = var.dynamodb_table_name
  }
}

module "ec2_erp" {
  source        = "../../../modules/compute/erp_ec2"
  ec2_name      = var.ec2_name
  environment   = var.environment
  app_subnet_id = data.terraform_remote_state.core.outputs.private_app_subnet_ids[0]
  eks_sg_ids    = data.terraform_remote_state.core.outputs.eks_node_sg_id
  key_pair_name = var.key_pair_name
  vpc_id_main   = data.terraform_remote_state.core.outputs.vpc_id
}

resource "aws_route53_record" "erp_endpoint" {
  zone_id = data.terraform_remote_state.core.outputs.route53_zone_id
  name    = "api.erp.internal"
  type    = "A"
  ttl     = 300
  records = [module.ec2_erp.private_ip]
}