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

module "core_eks" {
    source = "../../modules/compute/eks"
    vpc_id_main = module.core_vpc.vpc_id
    eks_name = var.eks-name
    private_subnets_ids = module.core_vpc.private_app_subnet_ids
    environment = var.environment
}

