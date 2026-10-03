variable "aws_region" {
  description = "Default region to deploy dev infra"
  type        = string
}

variable "environment" {
  description = "terraform dev environment"
  type        = string
}

variable "vpc_name" {
  description = "name of the deploy vpc"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC root network"
  type        = string
}

variable "azs" {
  description = "Deploy default Availability Zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Default public subnets"
  type        = list(string)
}

variable "app_subnets" {
  description = "Default private app subnets"
  type        = list(string)
}

variable "db_subnets" {
  description = "Default private db subnets"
  type        = list(string)
}

variable "eks-name" {
  description = "Nombre del clúster EKS"
  type        = string
}

variable "ec2-instance-name" {
  description = "Nombre de la instancia EC2 para ERPNext"
  type        = string
}

variable "key_pair_name" {
  description = "Nombre del Key Pair registrado en AWS EC2"
  type        = string
  default     = ""
}

variable "erp_target" {
  description = "Estrategia de persistencia: 'cloud', 'onpremise' o 'none'"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["cloud", "onpremise", "none"], var.erp_target)
    error_message = "La variable erp_target debe ser estrictamente 'cloud', 'onpremise' o 'none'."
  }
}

variable "onprem_erp_ip" {
  description = "IP interna/Tailscale del servidor on-premise si erp_target es 'onpremise'"
  type        = string
  default     = ""
}

variable "admin_principal_arn" {
  description = "ARN del usuario/rol IAM local a registrar como cluster-admin"
  type        = string
  default     = ""
}