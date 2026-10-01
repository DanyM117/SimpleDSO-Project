# 1. Namespace dedicado para el operador
resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# 2. Despliegue del Helm Chart con CRDs incluidos
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.external_secrets.metadata[0].name

  wait          = true
  timeout       = 300
  recreate_pods = true

  values = [
    yamlencode({
      installCRDs = true

      # ServiceAccount con el nombre exacto mapeado en Pod Identity
      serviceAccount = {
        create = true
        name   = "external-secrets"
      }

      # Recursos base dimensionados para nodos t4g.small (ARM64)
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

      webhook = {
        resources = {
          requests = {
            cpu    = "20m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
      }

      certController = {
        resources = {
          requests = {
            cpu    = "20m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.external_secrets
  ]
}