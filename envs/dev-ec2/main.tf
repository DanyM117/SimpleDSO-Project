data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_arm" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-arm64"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# 1. VPC Simple con CERO costo fijo (Sin NAT Gateways)
resource "aws_vpc" "monolith_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "simpledso-monolith-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.monolith_vpc.id
  tags   = { Name = "simpledso-monolith-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.monolith_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = { Name = "simpledso-monolith-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.monolith_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "simpledso-monolith-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "monolith_sg" {
  name        = "simpledso-monolith-sg"
  vpc_id      = aws_vpc.monolith_vpc.id

  ingress {
    description = "Trafico HTTP unificado (Nginx -> Agente IA y ERPNext)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida a internet para Bedrock, ECR y repositorios"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Rol IAM e Instance Profile (Bedrock + SSM + ECR)
resource "aws_iam_role" "ec2_role" {
  name = "simpledso-monolith-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "bedrock_access" {
  name = "BedrockInferenceAccess"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = [
        "arn:aws:bedrock:*::foundation-model/*",
        "arn:aws:bedrock:*:*:inference-profile/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "simpledso-monolith-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# 4. ECR Privado para la Imagen del Agente
resource "aws_ecr_repository" "agent_repo" {
  name                 = "simpledso-agent"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 5. Instancia EC2 Unificada (Dimensionamiento Dinamico segun ERP)
resource "aws_instance" "monolith" {
  ami                    = data.aws_ami.amazon_linux_arm.id
  instance_type          = var.erp_target == "cloud" ? "t4g.large" : "t4g.small"
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.monolith_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker git
              systemctl enable --now docker

              # Instalar Docker Compose CLI plugin ARM64
              mkdir -p /usr/local/lib/docker/cli-plugins
              curl -sSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64 -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

              # Swap de 4GB para amortiguar picos de memoria de Frappe/Python
              fallocate -l 4G /swapfile
              chmod 600 /swapfile
              mkswap /swapfile
              swapon /swapfile
              echo '/swapfile none swap sw 0 0' >> /etc/fstab
              EOF

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "simpledso-monolith-instance"
  }
}