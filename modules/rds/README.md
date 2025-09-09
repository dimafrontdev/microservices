# Universal RDS Terraform Module

This module creates a flexible database solution that can deploy either a traditional RDS instance or an Aurora cluster based on the `use_aurora` variable.

## Features

- **Dual Mode Support**: Switch between RDS instance and Aurora cluster using `use_aurora` flag
- **Multi-Engine Support**: PostgreSQL and MySQL for both RDS and Aurora
- **Automatic Resource Creation**:
  - DB Subnet Group
  - Security Group with configurable ingress rules
  - Parameter Groups with optimized settings
- **Production Ready**: Encryption, backups, monitoring, and high availability options
- **Flexible Configuration**: Extensive variables for customization

## Architecture

When `use_aurora = false`:
- Creates `aws_db_instance`
- Creates `aws_db_parameter_group`
- Single database instance

When `use_aurora = true`:
- Creates `aws_rds_cluster`
- Creates `aws_rds_cluster_parameter_group`
- Creates `aws_db_parameter_group` for instances
- Creates `aws_rds_cluster_instance` resources (configurable count)

## Usage Examples

### PostgreSQL RDS Instance

```hcl
module "postgres_rds" {
  source = "./modules/rds"
  
  # Basic Configuration
  use_aurora     = false
  engine         = "postgres"
  engine_version = "14.10"
  instance_class = "db.t3.micro"
  
  # Database Configuration
  db_name  = "myapp"
  username = "dbadmin"
  password = "MySecretPassword123!"
  
  # Network Configuration
  vpc_id                        = module.vpc.vpc_id
  subnet_ids                   = module.vpc.private_subnet_ids
  allowed_security_group_ids   = [aws_security_group.app.id]
  allowed_cidr_blocks          = ["10.0.0.0/8"]
  
  # Environment
  environment   = "production"
  project_name  = "myproject"
  
  # Storage Configuration
  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true
  
  # High Availability
  multi_az = true
  
  # Backup Configuration
  backup_retention_period = 30
  skip_final_snapshot    = false
  deletion_protection    = true
}
```

### MySQL Aurora Cluster

```hcl
module "mysql_aurora" {
  source = "./modules/rds"
  
  # Basic Configuration
  use_aurora        = true
  engine           = "aurora-mysql"
  engine_version   = "8.0.mysql_aurora.3.02.0"
  aurora_instance_class = "db.r5.large"
  aurora_cluster_size   = 3
  
  # Database Configuration
  db_name  = "webapp"
  username = "admin"
  password = "AuroraSecretPass123!"
  
  # Network Configuration
  vpc_id                        = module.vpc.vpc_id
  subnet_ids                   = module.vpc.private_subnet_ids
  allowed_security_group_ids   = [aws_security_group.eks.id]
  
  # Environment
  environment   = "production"
  project_name  = "webapp"
  
  # Monitoring
  performance_insights_enabled = true
  monitoring_interval         = 60
  
  # Backup Configuration
  backup_retention_period = 35
  skip_final_snapshot    = false
  deletion_protection    = true
}
```

### Development Environment (Minimal Configuration)

```hcl
module "dev_postgres" {
  source = "./modules/rds"
  
  # Minimal required variables
  password   = "DevPassword123!"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Development-specific settings
  environment            = "dev"
  skip_final_snapshot   = true
  deletion_protection   = false
  multi_az              = false
  
  allowed_security_group_ids = [aws_security_group.dev_app.id]
}
```

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `password` | Database password | `string` |
| `vpc_id` | VPC ID where to create the database | `string` |
| `subnet_ids` | List of subnet IDs for database subnet group | `list(string)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `use_aurora` | Whether to use Aurora cluster (true) or RDS instance (false) | `bool` | `false` |
| `engine` | Database engine (mysql, postgres, aurora-mysql, aurora-postgresql) | `string` | `"postgres"` |
| `engine_version` | Database engine version | `string` | `"14.10"` |
| `instance_class` | Database instance class | `string` | `"db.t3.micro"` |
| `db_name` | Database name | `string` | `"myapp"` |
| `username` | Database username | `string` | `"dbadmin"` |
| `environment` | Environment name | `string` | `"dev"` |
| `project_name` | Project name for resource naming | `string` | `"myproject"` |
| `allocated_storage` | Allocated storage for RDS instance (in GB) | `number` | `20` |
| `max_allocated_storage` | Maximum allocated storage for autoscaling (in GB) | `number` | `100` |
| `multi_az` | Enable Multi-AZ deployment | `bool` | `false` |
| `backup_retention_period` | Backup retention period (days) | `number` | `7` |
| `storage_encrypted` | Enable storage encryption | `bool` | `true` |
| `aurora_cluster_size` | Number of instances in Aurora cluster | `number` | `1` |
| `aurora_instance_class` | Aurora instance class | `string` | `"db.r5.large"` |
| `allowed_cidr_blocks` | List of CIDR blocks allowed to access the database | `list(string)` | `[]` |
| `allowed_security_group_ids` | List of security group IDs allowed to access the database | `list(string)` | `[]` |

[See variables.tf for complete list]

## Outputs

### Common Outputs (Both RDS and Aurora)

| Name | Description |
|------|-------------|
| `database_endpoint` | Database endpoint (works for both RDS and Aurora) |
| `database_port` | Database port |
| `database_name` | Name of the database |
| `database_engine` | Database engine |
| `security_group_id` | ID of the database security group |
| `connection_string` | Connection string for the database (sensitive) |

### RDS-Specific Outputs

| Name | Description |
|------|-------------|
| `rds_instance_id` | ID of the RDS instance |
| `rds_instance_arn` | ARN of the RDS instance |
| `rds_instance_endpoint` | Endpoint of the RDS instance |

### Aurora-Specific Outputs

| Name | Description |
|------|-------------|
| `aurora_cluster_id` | ID of the Aurora cluster |
| `aurora_cluster_endpoint` | Writer endpoint of the Aurora cluster |
| `aurora_cluster_reader_endpoint` | Reader endpoint of the Aurora cluster |
| `aurora_instance_endpoints` | List of Aurora instance endpoints |
| `aurora_cluster_members` | List of Aurora cluster members |

## Parameter Groups

The module automatically creates optimized parameter groups for each database engine:

### PostgreSQL Parameters
- `max_connections = 200`
- `shared_preload_libraries = pg_stat_statements`
- `log_statement = all`
- `work_mem = 4MB`
- `effective_cache_size = 1GB`

### MySQL Parameters
- `max_connections = 200`
- `innodb_buffer_pool_size = {DBInstanceClassMemory*3/4}`
- `query_cache_type = 1`
- `slow_query_log = 1`
- `long_query_time = 2`

## Security

### Network Security
- Creates dedicated security group for database
- Supports both CIDR block and security group ID based access control
- Database deployed in private subnets only (via `subnet_ids`)

### Data Security
- Storage encryption enabled by default (`storage_encrypted = true`)
- Backup encryption included with storage encryption
- Sensitive outputs (passwords, connection strings) marked as sensitive

### Access Control
- No public accessibility by default (`publicly_accessible = false`)
- Deletion protection available for production environments
- Final snapshots configurable

## Monitoring and Maintenance

### Backup Configuration
- Automated backups with configurable retention (1-35 days)
- Configurable backup and maintenance windows
- Final snapshot creation on deletion (configurable)

### Monitoring Options
- Enhanced Monitoring support (configurable interval)
- Performance Insights support
- CloudWatch Logs exports for database logs

### High Availability
- Multi-AZ deployment for RDS instances
- Aurora clusters provide built-in high availability
- Automatic failover capabilities

## Engine Versions

### Supported PostgreSQL Versions
- PostgreSQL 14.x (default: 14.10)
- PostgreSQL 13.x, 15.x also supported

### Supported MySQL Versions
- MySQL 8.0.x
- Aurora MySQL 8.0.mysql_aurora.3.02.0

## Cost Optimization

### Development Environments
- Use `db.t3.micro` instance class
- Disable Multi-AZ (`multi_az = false`)
- Reduce backup retention period
- Skip final snapshots (`skip_final_snapshot = true`)

### Production Environments
- Use appropriate instance classes (db.r5.large+ for Aurora)
- Enable Multi-AZ for RDS instances
- Enable Performance Insights and Enhanced Monitoring
- Set appropriate backup retention (7-35 days)

## Migration Path

### RDS to Aurora Migration
1. Create Aurora cluster with same configuration
2. Use AWS Database Migration Service (DMS)
3. Switch application connection strings
4. Decomission RDS instance

### Configuration Changes
The module allows switching between RDS and Aurora by changing the `use_aurora` variable, but this requires data migration.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## License

This module is part of the DevOps training project.