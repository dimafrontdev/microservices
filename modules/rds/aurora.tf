# Aurora Cluster (when use_aurora = true)
resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  # Basic Configuration
  cluster_identifier      = "${var.project_name}-${var.environment}-aurora-cluster"
  engine                 = var.engine
  engine_version         = var.engine_version
  engine_mode            = "provisioned"

  # Database Configuration
  database_name   = var.db_name
  master_username = var.username
  master_password = var.password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  # Backup Configuration
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  copy_tags_to_snapshot       = true

  # Storage Configuration
  storage_encrypted = var.storage_encrypted

  # Parameter Groups
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.main[0].name
  db_instance_parameter_group_name = aws_db_parameter_group.aurora_instance[0].name

  # Monitoring
  enabled_cloudwatch_logs_exports = var.engine == "aurora-mysql" ? ["audit", "error", "general", "slowquery"] : ["postgresql"]

  # Deletion Protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = var.deletion_protection

  # Apply changes immediately (for dev environments)
  apply_immediately = var.environment == "dev" ? true : false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-cluster"
    Type = "Aurora Cluster"
  })

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.database,
    aws_rds_cluster_parameter_group.main,
    aws_db_parameter_group.aurora_instance
  ]
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.use_aurora ? var.aurora_cluster_size : 0

  identifier          = "${var.project_name}-${var.environment}-aurora-${count.index + 1}"
  cluster_identifier  = aws_rds_cluster.main[0].id
  instance_class      = var.aurora_instance_class
  engine              = aws_rds_cluster.main[0].engine
  engine_version      = aws_rds_cluster.main[0].engine_version
  publicly_accessible = var.publicly_accessible

  # Parameter Group
  db_parameter_group_name = aws_db_parameter_group.aurora_instance[0].name

  # Monitoring
  monitoring_interval   = var.monitoring_interval
  monitoring_role_arn   = var.monitoring_interval > 0 ? aws_iam_role.aurora_monitoring[0].arn : null
  performance_insights_enabled = var.performance_insights_enabled

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = true

  # Apply changes immediately (for dev environments)
  apply_immediately = var.environment == "dev" ? true : false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-${count.index + 1}"
    Type = "Aurora Instance"
    Role = count.index == 0 ? "Writer" : "Reader"
  })

  depends_on = [aws_rds_cluster.main]
}

# IAM Role for Aurora Enhanced Monitoring (when monitoring_interval > 0)
resource "aws_iam_role" "aurora_monitoring" {
  count = var.monitoring_interval > 0 && var.use_aurora ? 1 : 0

  name = "${var.project_name}-${var.environment}-aurora-monitoring-role"

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
    Name = "${var.project_name}-${var.environment}-aurora-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "aurora_monitoring" {
  count = var.monitoring_interval > 0 && var.use_aurora ? 1 : 0

  role       = aws_iam_role.aurora_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}