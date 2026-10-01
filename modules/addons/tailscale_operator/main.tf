data "aws_secretsmanager_secret_version" "oauth" {
  secret_id = var.secret_arn
}

locals {
  tailscale_creds = jsondecode(data.aws_secretsmanager_secret_version.oauth.secret_string)
}

# 1. Namespace dedicado
resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# 2. Secreto nativo de Kubernetes requerido por el Chart
resource "kubernetes_secret_v1" "operator_oauth" {
  metadata {
    name      = "operator-oauth"
    namespace = kubernetes_namespace_v1.tailscale.metadata[0].name
  }

  data = {
    client_id     = local.tailscale_creds["client_id"]
    client_secret = local.tailscale_creds["client_secret"]
  }

  type = "Opaque"
}

# 3. Helm Release del Operador
resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.tailscale.metadata[0].name

  wait          = true
  timeout       = 300
  recreate_pods = true

  values = [
    yamlencode({
      oauth = {
        secret = kubernetes_secret_v1.operator_oauth.metadata[0].name
      }
      operatorConfig = {
        defaultTags = [var.operator_tags]
      }
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "128Mi"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret_v1.operator_oauth
  ]
}