output "vpc_id" { value = module.aws_vpc.vpc_id }
output "private_app_subnet_ids" { value = module.aws_vpc.private_subnets }
output "private_db_subnet_ids" { value = module.aws_vpc.database_subnets }
output "public_subnet_ids" { value = module.aws_vpc.public_subnets }
output "database_subnet_group_name" {
  description = "Nombre del Database Subnet Group administrado por la VPC"
  value       = module.aws_vpc.database_subnet_group_name
}