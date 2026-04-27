output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = "${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}"
}

output "address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.postgres.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_db_instance.postgres.db_name
}

output "instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.postgres.id
}

output "arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.postgres.arn
}

output "security_group_id" {
  description = "Security group ID for the database"
  value       = aws_security_group.postgres.id
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "connection_string" {
  description = "PostgreSQL connection string (password in Secrets Manager)"
  value       = "postgresql://${var.master_username}:PASSWORD@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.database_name}"
  sensitive   = true
}
