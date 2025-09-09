# RDS Instance (when use_aurora = false)
resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  # Basic Configuration
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted

  # Database Configuration
  db_name  = var.db_name
  username = var.username
  password = var.password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = var.publicly_accessible

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # High Availability
  multi_az = var.multi_az

  # Parameter Group
  parameter_group_name = var.use_aurora ? null : aws_db_parameter_group.main[0].name

  # Monitoring
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn            = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  performance_insights_enabled   = var.performance_insights_enabled
  enabled_cloudwatch_logs_exports = var.engine == "mysql" ? ["audit", "error", "general", "slowquery"] : ["postgresql", "upgrade"]

  # Deletion Protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  deletion_protection       = var.deletion_protection

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = true

  # Apply changes immediately (for dev environments)
  apply_immediately = var.environment == "dev" ? true : false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db"
    Type = "RDS Instance"
  })

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.database,
    aws_db_parameter_group.main
  ]
}

# IAM Role for Enhanced Monitoring (when monitoring_interval > 0)
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 && !var.use_aurora ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 && !var.use_aurora ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}