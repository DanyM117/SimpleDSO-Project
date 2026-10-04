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

# 2. Security Group Perimetral (Sin Puerto 22 SSH abierto)
resource "aws_security_group" "monolith_sg" {
  name        = "simpledso-monolith-sg"
  description = "Trafico web para el Agente y ERPNext; administracion exclusiva por SSM"
  vpc_id      = aws_vpc.monolith_vpc.id

  ingress {
    description = "HTTP Publico (Agente / Webhook WhatsApp / ERP)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Publico"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida total a Internet via IGW (Bedrock, ECR, actualizaciones)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "simpledso-monolith-sg" }
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

# 5. Instancia EC2 Unificada (Dimensionamiento Dinámico según ERP)
resource "aws_instance" "monolith" {
  ami                  = data.aws_ami.amazon_linux_arm.id
  # Si corre ERPNext local requiere 8 GB RAM (t4g.large); si es on-premise basta 2 GB RAM (t4g.small)
  instance_type        = var.erp_target == "cloud" ? "t4g.large" : "t4g.small"
  subnet_id            = aws_subnet.public.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.monolith_sg.id]

  # User data para habilitar Swap y preparar Docker
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl enable --now docker

              # Swap de 4GB para amortiguar consumo de memoria de Frappe/Python
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

  tags = {
    Name = "simpledso-monolith-instance"
  }
}