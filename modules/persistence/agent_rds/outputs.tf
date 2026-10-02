output "db_instance_id" {
  description = "Identificador de la instancia RDS"
  value       = aws_db_instance.agent_postgres.id
}

output "db_instance_endpoint" {
  description = "Endpoint completo de conexion (host:puerto)"
  value       = aws_db_instance.agent_postgres.endpoint
}

output "db_instance_address" {
  description = "Direccion DNS privada del host PostgreSQL"
  value       = aws_db_instance.agent_postgres.address
}

output "db_instance_port" {
  description = "Puerto de escucha de la base de datos"
  value       = aws_db_instance.agent_postgres.port
}

output "db_security_group_id" {
  description = "ID del Security Group asignado a la base de datos"
  value       = aws_security_group.rds_sg.id
}

output "master_user_secret_arn" {
  description = "ARN del secreto administrado en AWS Secrets Manager con las credenciales maestras"
  value       = aws_db_instance.agent_postgres.master_user_secret[0].secret_arn
}
output "master_user_secret_arn" {
  description = "ARN del secreto determinista en AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}