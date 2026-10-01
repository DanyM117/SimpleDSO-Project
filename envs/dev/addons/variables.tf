variable "aws_region" {
  description = "Región de AWS de despliegue"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno objetivo"
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "Nombre del bucket S3 que almacena el tfstate de core"
  type        = string
}

variable "tailscale_oauth_secret_name" {
  description = "Nombre del secreto en AWS Secrets Manager con las credenciales OAuth de Tailscale"
  type        = string
  default     = "dev/tailscale/oauth"
}

variable "tailscale_chart_version" {
  description = "Versión del Helm chart de Tailscale Operator"
  type        = string
  default     = "1.74.0"
}

variable "eso_chart_version" {
  description = "Versión del Helm chart de External Secrets Operator"
  type        = string
  default     = "0.14.2"
}