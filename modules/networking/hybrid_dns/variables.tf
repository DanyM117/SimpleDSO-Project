variable "vpc_id" {
  description = "ID de la VPC a la que se asociará la Private Hosted Zone"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde reside la VPC"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Dominio raíz para la zona DNS privada"
  type        = string
  default     = "erp.internal"
}

variable "record_name" {
  description = "Subdominio o nombre del registro (ej. 'api')"
  type        = string
  default     = "api"
}

variable "erp_target" {
  description = "Estrategia de persistencia: 'cloud', 'onpremise' o 'none'"
  type        = string

  validation {
    condition     = contains(["cloud", "onpremise", "none"], var.erp_target)
    error_message = "La variable erp_target debe ser estrictamente 'cloud', 'onpremise' o 'none'."
  }
}

variable "cloud_private_ip" {
  description = "IP privada de la instancia EC2 en AWS (requerida si erp_target == 'cloud')"
  type        = string
  default     = ""
}

variable "onprem_ip" {
  description = "IP interna/Tailscale del servidor físico on-premise (requerida si erp_target == 'onpremise')"
  type        = string
  default     = ""
}

variable "ttl" {
  description = "Time-to-Live del registro DNS en segundos"
  type        = number
  default     = 300
}

variable "environment" {
  description = "Etiqueta de entorno (dev, staging, prod)"
  type        = string
}