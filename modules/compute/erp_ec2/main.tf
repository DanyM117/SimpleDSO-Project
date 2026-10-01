data "aws_ami" "amazon_linux_arm" {
  most_recent = true
  owners      = ["137112412989"] # AWS Amazon Linux AMI Owner ID

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_security_group_to" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.ec2_name}-sg"
  description = "sg-ec2-erp"
  vpc_id      = var.vpc_id_main

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Permitir HTTP (80) desde nodos de EKS"
      source_security_group_id = var.eks_sg_ids
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Permitir HTTPS (443) desde nodos de EKS"
      source_security_group_id = var.eks_sg_ids
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

module "ec2_erp" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7"

  name                   = var.ec2_name
  ami                    = data.aws_ami.amazon_linux_arm.id
  instance_type          = "t4g.medium"
  key_name               = var.key_pair_name
  monitoring             = true
  subnet_id              = var.app_subnet_id
  vpc_security_group_ids = [module.ec2_security_group_to.security_group_id]

  enable_volume_tags = true
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 40
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}