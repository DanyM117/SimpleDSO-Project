data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Prefijo comodín para secretos del entorno (API keys de ERPNext, canales de mensajería)
  env_secrets_wildcard = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.project_prefix}/${var.environment}/*"

  # Consolidación de recursos autorizados sin duplicados ni nulos
  target_secret_arns = distinct(compact(concat(
    [local.env_secrets_wildcard],
    var.agent_db_secret_arn != "" ? [var.agent_db_secret_arn] : [],
    var.additional_secret_arns
  )))
}

# 1. Política de Confianza de Pod Identity
data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# 2. Rol IAM asumido exclusivamente por los pods de Kubernetes
resource "aws_iam_role" "agent_pod_identity" {
  name               = "${var.project_prefix}-${var.environment}-agent-pod-role"
  description        = "Rol IAM Zero-Trust para microservicio del Agente IA en EKS"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 3. Política de Mínimo Privilegio sobre AWS Secrets Manager
data "aws_iam_policy_document" "agent_secrets_access" {
  statement {
    sid    = "AllowSecretRetrieval"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = local.target_secret_arns
  }

  statement {
    sid    = "AllowBedrockInference"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:${local.region}::foundation-model/anthropic.claude-3-5-haiku-20241022-v1:0",
      "arn:aws:bedrock:${local.region}::foundation-model/amazon.nova-lite-v1:0"
    ]
  }
}

resource "aws_iam_policy" "agent_secrets_policy" {
  name        = "${var.project_prefix}-${var.environment}-agent-secrets-policy"
  description = "Permisos de lectura granular en Secrets Manager para el agente"
  policy      = data.aws_iam_policy_document.agent_secrets_access.json

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.agent_pod_identity.name
  policy_arn = aws_iam_policy.agent_secrets_policy.arn
}

# 4. Asociación nativa EKS Pod Identity
resource "aws_eks_pod_identity_association" "agent_association" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.agent_pod_identity.arn

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 1. Rol IAM para el controlador de External Secrets Operator
resource "aws_iam_role" "eso_controller_role" {
  name               = "${var.project_prefix}-${var.environment}-eso-controller-role"
  description        = "Rol IAM para que External Secrets Operator lea de Secrets Manager"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 2. Reutilización de la política de lectura de secretos
resource "aws_iam_role_policy_attachment" "attach_eso_secrets_policy" {
  role       = aws_iam_role.eso_controller_role.name
  policy_arn = aws_iam_policy.agent_secrets_policy.arn
}

# 3. Asociación EKS Pod Identity para el ServiceAccount de ESO
resource "aws_eks_pod_identity_association" "eso_association" {
  cluster_name    = var.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eso_controller_role.arn

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}