variable "eks_name" { type = string }
variable "private_subnets_ids" { type = list(string)}
variable "environment" { type = string }
variable "vpc_id_main" { type = string }
variable "admin_principal_arn" {
  description = "ARN del IAM Principal para acceso de administrador local al clúster"
  type        = string
  default     = ""
}