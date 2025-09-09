locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
  
  db_port = var.engine == "mysql" || var.engine == "aurora-mysql" ? 3306 : 5432
  
  parameter_group_family = var.use_aurora ? (
    var.engine == "aurora-mysql" ? "aurora-mysql8.0" : "aurora-postgresql14"
  ) : (
    var.engine == "mysql" ? "mysql8.0" : "postgres14"
  )
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# Security Group for Database
resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "Security group for ${var.project_name} database"
  vpc_id      = var.vpc_id

  # Ingress rule for database port
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = local.db_port
      to_port     = local.db_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Database access from ${ingress.value}"
    }
  }

  # Ingress rule for security groups
  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port       = local.db_port
      to_port         = local.db_port
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "Database access from security group ${ingress.value}"
    }
  }

  # Egress rule (allow all outbound)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-database-sg"
  })
}

# Parameter Group for RDS
resource "aws_db_parameter_group" "main" {
  count = var.use_aurora ? 0 : 1
  
  family = local.parameter_group_family
  name   = "${var.project_name}-${var.environment}-db-params"

  dynamic "parameter" {
    for_each = var.engine == "mysql" ? {
      max_connections        = "200"
      innodb_buffer_pool_size = "{DBInstanceClassMemory*3/4}"
      query_cache_type      = "1"
      query_cache_size      = "32M"
      slow_query_log        = "1"
      long_query_time       = "2"
    } : {
      shared_preload_libraries      = "pg_stat_statements"
      log_statement                 = "all"
      log_min_duration_statement    = "1000"
      log_min_messages              = "info"
      log_checkpoints               = "1"
      log_connections               = "1"
      log_disconnections            = "1"
      log_lock_waits                = "1"
      log_temp_files                = "0"
    }
    
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-params"
  })
}

# Cluster Parameter Group for Aurora
resource "aws_rds_cluster_parameter_group" "main" {
  count = var.use_aurora ? 1 : 0
  
  family = local.parameter_group_family
  name   = "${var.project_name}-${var.environment}-aurora-cluster-params"

  dynamic "parameter" {
    for_each = var.engine == "aurora-mysql" ? {
      max_connections           = "200"
      innodb_buffer_pool_size  = "{DBInstanceClassMemory*3/4}"
      query_cache_type         = "1"
      query_cache_size         = "32M"
      slow_query_log           = "1"
      long_query_time          = "2"
      binlog_format            = "ROW"
    } : {
      shared_preload_libraries      = "pg_stat_statements"
      log_statement                 = "all"
      log_min_duration_statement    = "1000"
    }
    
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-cluster-params"
  })
}

# DB Parameter Group for Aurora instances
resource "aws_db_parameter_group" "aurora_instance" {
  count = var.use_aurora ? 1 : 0
  
  family = local.parameter_group_family
  name   = "${var.project_name}-${var.environment}-aurora-instance-params"

  dynamic "parameter" {
    for_each = var.engine == "aurora-mysql" ? {
      slow_query_log     = "1"
      long_query_time    = "2"
      general_log        = "1"
    } : {
      log_statement                 = "all"
      log_min_duration_statement    = "1000"
      shared_preload_libraries      = "pg_stat_statements"
    }
    
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-instance-params"
  })
}