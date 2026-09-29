variable "eks_name" { type = string }
variable "private_subnets_ids" { type = list(string)}
variable "environment" { type = string }
variable "vpc_id_main" { type = string }