module "aws_vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "~>5.0"
    
    name = var.vpc_name
    cidr = var.vpc_cidr

    azs = var.azs
    public_subnets = var.public_subnets
    private_subnets = var.app_subnets
    database_subnets = var.db_subnets

    enable_dns_hostnames = true
    enable_dns_support = true

    enable_nat_gateway = true
    single_nat_gateway = var.environment == "prod" ? false : true

    create_database_subnet_group = true
    create_database_subnet_route_table = true
    create_database_internet_gateway_route = false

    public_subnet_tags = {
        "kubernetes.io/role/internal-elb" = 1
        "Tier" = "Private-App"
    }
    database_subnet_tags = {
        "Tier" = "Private-Data"
    }

}