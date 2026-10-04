terraform {
  backend "s3" {
    key     = "dev/ec2-monolith/terraform.tfstate"
    encrypt = true
  }
}