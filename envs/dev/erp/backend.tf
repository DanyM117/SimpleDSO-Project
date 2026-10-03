terraform {
  backend "s3" {
    key     = "dev/erp/terraform.tfstate"
    encrypt = true
  }
}