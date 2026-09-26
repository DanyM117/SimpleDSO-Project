module "core_vpc" {
    source = "../../modules/networking/vpc"

    environment = var.environment
    aws_region = var.aws_region
    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
    azs = var.azs
    public_subnets = var.public_subnets
    app_subnets = var.app_subnets
    db_subnets = var.db_subnets
}

