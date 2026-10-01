variable "cluster_name" {
  description = "Nombre del clúster EKS objetivo"
  type        = string
}

variable "secret_arn" {
  description = "ARN del secreto en AWS Secrets Manager con el OAuth de Tailscale"
  type        = string
}

variable "operator_tags" {
  description = "Tags que aplicará el operador a los nodos efímeros creados"
  type        = string
  default     = "tag:k8s"
}

variable "chart_version" {
  description = "Versión del chart de Helm de Tailscale"
  type        = string
  default     = "1.74.0" # Ajustar a la versión estable actual
}