terraform {
  backend "s3" {
    key     = "dev/addons/terraform.tfstate"
    encrypt = true
  }
}