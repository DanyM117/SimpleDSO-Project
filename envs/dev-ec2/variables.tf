variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "erp_target" {
  type        = string
  default     = "cloud"
  description = "Estrategia: cloud (ERPNext local en la EC2) u onpremise (ERPNext remoto vía Tailscale)"
}