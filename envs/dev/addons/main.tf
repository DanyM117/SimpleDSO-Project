# 1. Lectura del estado del clúster core
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket         = var.state_bucket_name
    key            = "dev/core/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "SimpleDSo-infra-tfstate-lock"
  }
}

# 2. Generación dinámica de tokens de autenticación para EKS
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.core.outputs.eks_cluster_name
}

# 3. Resolución dinámica del ARN del secreto OAuth de Tailscale
data "aws_secretsmanager_secret" "tailscale_oauth" {
  name = var.tailscale_oauth_secret_name
}

# 4. Configuración del proveedor de Kubernetes
provider "kubernetes" {
  host                   = data.terraform_remote_state.core.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.core.outputs.eks_cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# 5. Configuración del proveedor de Helm (Sintaxis v3.x)
provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.core.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.core.outputs.eks_cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# 6. Operador de Red: Tailscale
module "tailscale_operator" {
  source = "../../../modules/addons/tailscale_operator"

  cluster_name  = data.terraform_remote_state.core.outputs.eks_cluster_name
  secret_arn    = data.aws_secretsmanager_secret.tailscale_oauth.arn
  operator_tags = "tag:k8s"
  chart_version = var.tailscale_chart_version
}

# 7. Operador de Secretos: External Secrets Operator (ESO)
module "external_secrets" {
  source = "../../../modules/addons/external_secrets"

  chart_version = var.eso_chart_version
  namespace     = "external-secrets"
}