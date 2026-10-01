variable "aws_region" {
    description = "Default region to deploy dev infra"
    type = string
}

variable "environment" {
    description = "terraform dev environment"
    type = string
}

variable "vpc_name" {
  description = "name of the deploy vpc"
  type = string
}

variable "vpc_cidr" {
  description = "VPC root network"
  type = string
}

variable "azs" {
  description = "Deploy default Availability Zones"
  type = list(string)
}

variable "public_subnets" {
  description = "Default public subnets"
  type = list(string)
}

variable "app_subnets" {
  description = "Default private app subnets"
  type = list(string)
}

variable "db_subnets" {
  description = "Default private db subnets"
  type = list(string)
}

variable "eks-name" { type = string }

variable "ec2-instance-name" { type = string }

variable "key_pair_name" { type = string }

variable "erp_target" { type = string }

variable "onprem_erp_ip" { type = string }