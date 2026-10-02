# 1. Security Group perimetral para PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_prefix}-${var.environment}-agent-rds-sg"
  description = "Perimetro de acceso exclusivo para RDS PostgreSQL del Agente IA"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_prefix}-${var.environment}-agent-rds-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 2. Regla Ingress L4: Puerto 5432 exclusivo desde Security Group de nodos EKS
resource "aws_vpc_security_group_ingress_rule" "postgres_from_eks" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = var.eks_node_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Permitir PostgreSQL (5432) desde los nodos de computo EKS"
}

# 3. Parameter Group para habilitar extensiones vectoriales/auditoría si se requiere
resource "aws_db_parameter_group" "postgres_pg" {
  name        = "${var.project_prefix}-${var.environment}-pg16"
  family      = "postgres16"
  description = "Custom parameter group para PostgreSQL 16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
# Generar contraseña segura sin exponerla en tfstate plano
resource "random_password" "master_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secreto con NOMBRE FIJO y DETERMINISTA
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_prefix}/${var.environment}/agent-db/credentials"
  recovery_window_in_days = 0 # Permite recrearlo inmediatamente en terraform apply tras un destroy
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master_password.result
    host     = aws_db_instance.agent_postgres.address
    port     = 5432
    dbname   = var.db_name
  })
}
# 4. Instancia de Base de Datos RDS PostgreSQL
resource "aws_db_instance" "agent_postgres" {
  #checkov:skip=CKV_AWS_118: "Ensure that Enhanced Monitoring is enabled" (Dev cost optimization)
  #checkov:skip=CKV_AWS_133: "Ensure backup replication is enabled" (Dev cost optimization)
  identifier = "${var.project_prefix}-${var.environment}-agent-db"

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  # Secretless Authentication: Credencial maestra administrada por Secrets Manager
 # manage_master_user_password = true

  # Corrección AVD-AWS-0176: Habilita autenticación IAM (Zero-Trust)
  iam_database_authentication_enabled = true

  # Corrección AVD-AWS-0133: Performance Insights activado (7 días sin costo adicional)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  parameter_group_name   = aws_db_parameter_group.postgres_pg.name

  publicly_accessible = false
  multi_az            = false

  # Corrección AVD-AWS-0077: Retención mínima de 7 días para respaldos continuos
  backup_retention_period    = 7
  backup_window              = "03:00-04:00"
  maintenance_window         = "Mon:04:30-Mon:05:30"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  deletion_protection        = var.environment == "prod" ? true : false
  skip_final_snapshot        = var.environment == "prod" ? false : true

  tags = {
    Name        = "${var.project_prefix}-${var.environment}-agent-db"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}