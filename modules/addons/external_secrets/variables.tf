variable "chart_version" {
  description = "Versión del chart de Helm de External Secrets Operator"
  type        = string
  default     = "0.14.2"
}

variable "namespace" {
  description = "Namespace donde operará el controlador"
  type        = string
  default     = "external-secrets"
}