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
  source                  = "../../modules/compute/eks"
  vpc_id_main             = module.core_vpc.vpc_id
  eks_name                = var.eks-name
  private_subnets_ids     = module.core_vpc.private_app_subnet_ids
  environment             = var.environment
  admin_principal_arn     = var.admin_principal_arn
}
# trivy:ignore:AVD-AWS-0031
# trivy:ignore:AWS-0031
resource "aws_ecr_repository" "agent_repo" {
  name                 = "simpledso-agent"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "hybrid_dns" {
  source = "../../modules/networking/hybrid_dns"

  vpc_id           = module.core_vpc.vpc_id
  aws_region       = var.aws_region
  environment      = var.environment
  domain_name      = "erp.internal"
  record_name      = "api"
  erp_target       = var.erp_target == "onpremise" ? "onpremise" : "none"
  cloud_private_ip = ""
  onprem_ip        = var.onprem_erp_ip
}

module "agent_rds" {
  source = "../../modules/persistence/agent_rds"
  environment            = var.environment
  project_prefix         = "simpledso"
  vpc_id                 = module.core_vpc.vpc_id
  db_subnet_group_name   = module.core_vpc.database_subnet_group_name
  eks_node_sg_id         = module.core_eks.eks_node_sg_id
  db_name                = "agent_core"
  db_username            = "agent_admin"
  instance_class         = "db.t4g.small" # Actualizado de db.t4g.micro para evitar InsufficientDBInstanceCapacity
  allocated_storage      = 20
  max_allocated_storage  = 50
}

module "agent_security" {
  source = "../../modules/security"

  environment          = var.environment
  project_prefix       = "simpledso"
  cluster_name         = module.core_eks.cluster_name
  namespace            = "default"
  service_account_name = "agent-core-sa"
  agent_db_secret_arn  = module.agent_rds.master_user_secret_arn
}

