output "vpc_id" { value = module.aws_vpc.vpc_id }
output "private_app_subnet_ids" { value = module.aws_vpc.private_subnets }
output "private_db_subnet_ids" { value = module.aws_vpc.database_subnets }
output "public_subnet_ids" { value = module.aws_vpc.public_subnets }