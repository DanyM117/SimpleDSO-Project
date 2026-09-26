environment = "dev"
aws_region = "us-east-1"
vpc_name = "simpldso-vpc"
vpc_cidr = "10.0.0.0/16"

azs = [ "us-east-1a", "us-east-1b" ]

# Public subnets
public_subnets = [
    "10.0.112.0/20",
    "10.0.144.0/20"
]

# Private subnets
app_subnets = [
    "10.0.16.0/20",
    "10.0.48.0/20"
]

db_subnets = [
    "10.0.32.0/20",
    "10.0.64.0/20"
]