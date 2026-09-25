terraform {
  backend "s3" {
    bucket = "simpledso-infra-tfstate-104091534720"
    key = "prod/core/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "SimpleDSo-infra-tfstate-lock"
  }
}