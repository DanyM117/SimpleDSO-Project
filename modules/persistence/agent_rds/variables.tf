variable "environment" {
  description = "Entorno de ejecución (dev, staging, prod)"
  type        = string
}

variable "project_prefix" {
  description = "Prefijo para nomenclatura de recursos"
  type        = string
  default     = "simpledso"
}

variable "vpc_id" {
  description = "ID de la VPC donde reside la base de datos"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Nombre del DB Subnet Group en subredes aisladas"
  type        = string
}

variable "eks_node_sg_id" {
  description = "Security Group ID de los nodos de EKS para autorizar tráfico entrante"
  type        = string
}

variable "db_name" {
  description = "Nombre inicial de la base de datos transaccional del agente"
  type        = string
  default     = "agent_core"
}

variable "db_username" {
  description = "Usuario maestro de la base de datos"
  type        = string
  default     = "agent_admin"
}

variable "instance_class" {
  description = "Tipo de cómputo para RDS (arquitectura Graviton)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento inicial asignado en GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Límite superior de autoescalado de almacenamiento en GB"
  type        = number
  default     = 50
}