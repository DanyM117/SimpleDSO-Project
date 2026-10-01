variable "environment" {
  description = "Entorno de ejecución (dev, staging, prod)"
  type        = string
}

variable "project_prefix" {
  description = "Prefijo para nomenclatura de recursos"
  type        = string
  default     = "simpledso"
}

variable "cluster_name" {
  description = "Nombre del clúster EKS donde opera el agente"
  type        = string
}

variable "namespace" {
  description = "Namespace de Kubernetes donde reside el microservicio del agente"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Nombre del Kubernetes ServiceAccount asociado al agente de IA"
  type        = string
  default     = "agent-core-sa"
}

variable "agent_db_secret_arn" {
  description = "ARN del secreto de Secrets Manager administrado por RDS"
  type        = string
  default     = ""
}

variable "additional_secret_arns" {
  description = "Lista opcional de ARNs específicos en Secrets Manager (ej. Frappe API keys, WhatsApp tokens)"
  type        = list(string)
  default     = []
}