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

module "erp_ec2" {
    source = "../../modules/compute/erp_ec2"

    count = var.erp_target == "cloud" ? 1 : 0

    ec2_name = var.ec2-instance-name
    environment = var.environment
    app_subnet_id = module.core_vpc.private_app_subnet_ids[0]
    eks_sg_ids = module.core_eks.eks-node-sg-id
    key_pair_name = var.key_pair_name # ENV VAR
    vpc_id_main = module.core_vpc.vpc_id
}

module "hybrid_dns" {
  source = "../../modules/networking/hybrid_dns"

  vpc_id           = module.core_vpc.vpc_id
  aws_region       = var.aws_region
  environment      = var.environment
  domain_name      = "erp.internal"
  record_name      = "api"
  erp_target       = var.erp_target
  cloud_private_ip = try(module.erp_ec2[0].private_ip, "")
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