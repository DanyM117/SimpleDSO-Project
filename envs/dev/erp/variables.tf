variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "state_bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type    = string
  default = "SimpleDSo-infra-tfstate-lock"
}

variable "ec2_name" {
  type    = string
  default = "simpledso-erp-instance"
}

variable "key_pair_name" {
  type    = string
  default = ""
}