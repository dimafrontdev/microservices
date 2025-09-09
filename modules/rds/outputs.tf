# Common outputs for both RDS and Aurora
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "database_port" {
  description = "Database port"
  value       = local.db_port
}

output "parameter_group_name" {
  description = "Name of the parameter group"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.main[0].name : aws_db_parameter_group.main[0].name
}

# RDS-specific outputs
output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].arn
}

output "rds_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].endpoint
}

output "rds_instance_address" {
  description = "Address of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.main[0].address
}

# Aurora-specific outputs
output "aurora_cluster_id" {
  description = "ID of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].id : null
}

output "aurora_cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].arn : null
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : null
}

output "aurora_cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "aurora_cluster_members" {
  description = "List of Aurora cluster members"
  value       = var.use_aurora ? aws_rds_cluster.main[0].cluster_members : null
}

output "aurora_instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = var.use_aurora ? [for instance in aws_rds_cluster_instance.cluster_instances : instance.endpoint] : null
}

output "aurora_instance_ids" {
  description = "List of Aurora instance IDs"
  value       = var.use_aurora ? [for instance in aws_rds_cluster_instance.cluster_instances : instance.id] : null
}

# Universal outputs (work for both RDS and Aurora)
output "database_endpoint" {
  description = "Database endpoint (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : aws_db_instance.main[0].endpoint
}

output "database_name" {
  description = "Name of the database"
  value       = var.db_name
}

output "database_username" {
  description = "Database username"
  value       = var.username
  sensitive   = true
}

output "database_engine" {
  description = "Database engine"
  value       = var.engine
}

output "database_engine_version" {
  description = "Database engine version"
  value       = var.engine_version
}

# Connection string outputs
output "connection_string" {
  description = "Connection string for the database"
  value = var.use_aurora ? (
    var.engine == "aurora-mysql" ?
    "mysql://${var.username}:${var.password}@${aws_rds_cluster.main[0].endpoint}:${local.db_port}/${var.db_name}" :
    "postgresql://${var.username}:${var.password}@${aws_rds_cluster.main[0].endpoint}:${local.db_port}/${var.db_name}"
  ) : (
    var.engine == "mysql" ?
    "mysql://${var.username}:${var.password}@${aws_db_instance.main[0].endpoint}:${local.db_port}/${var.db_name}" :
    "postgresql://${var.username}:${var.password}@${aws_db_instance.main[0].endpoint}:${local.db_port}/${var.db_name}"
  )
  sensitive = true
}

# Environment and resource information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "is_aurora" {
  description = "Whether this is an Aurora cluster"
  value       = var.use_aurora
}

output "multi_az_enabled" {
  description = "Whether Multi-AZ is enabled"
  value       = var.use_aurora ? true : var.multi_az
}

output "backup_retention_period" {
  description = "Backup retention period in days"
  value       = var.backup_retention_period
}

output "storage_encrypted" {
  description = "Whether storage is encrypted"
  value       = var.storage_encrypted
}