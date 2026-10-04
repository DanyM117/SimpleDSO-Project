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

# Rol IAM para la instancia EC2
resource "aws_iam_role" "erp_ssm_role" {
  name = "${var.ec2_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.erp_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "erp_profile" {
  name = "${var.ec2_name}-instance-profile"
  role = aws_iam_role.erp_ssm_role.name
}

module "ec2_erp" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7"

  name                   = var.ec2_name
  iam_instance_profile = aws_iam_instance_profile.erp_profile.name
  ami                    = data.aws_ami.amazon_linux_arm.id
  instance_type          = "t4g.medium"
  key_name               = var.key_pair_name
  monitoring             = true
  subnet_id              = var.app_subnet_id
  vpc_security_group_ids = [module.ec2_security_group_to.security_group_id]
  enable_volume_tags     = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker python3
              systemctl enable --now docker

              # Servidor API ligero para responder a las herramientas del agente
              cat << 'PYEOF' > /home/ec2-user/erp_service.py
              from http.server import HTTPServer, BaseHTTPRequestHandler
              import json

              class Handler(BaseHTTPRequestHandler):
                  def do_GET(self):
                      self.send_response(200)
                      self.send_header('Content-Type', 'application/json')
                      self.end_headers()
                      if "/Item" in self.path:
                          data = {"data": [
                              {"name": "SERV-001", "item_name": "Consulta General", "standard_rate": 500},
                              {"name": "SERV-002", "item_name": "Corte y Estilo", "standard_rate": 350}
                          ]}
                      else:
                          data = {"data": []}
                      self.wfile.write(json.dumps(data).encode())

                  def do_POST(self):
                      self.send_response(200)
                      self.send_header('Content-Type', 'application/json')
                      self.end_headers()
                      self.wfile.write(json.dumps({"data": {"name": "APPT-2026-001"}}).encode())

              HTTPServer(('0.0.0.0', 80), Handler).serve_forever()
              PYEOF

              python3 /home/ec2-user/erp_service.py &
              EOF

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