# Lesson DB Module - Універсальний модуль баз даних 🗄️

## Опис проєкту
Універсальний Terraform модуль для розгортання баз даних на AWS, який підтримує як традиційні **RDS інстанси**, так і **Aurora кластери**.

---

## Ключові можливості
- **Подвійна підтримка**: RDS інстанси та Aurora кластери через прапор `use_aurora`
- **Багато двигунів**: PostgreSQL та MySQL для RDS і Aurora
- **Автоматичне створення**: DB Subnet Group, Security Group, Parameter Groups
- **Production-ready**: шифрування, бекапи, моніторинг, висока доступність

---

## Приклади використання модуля

### PostgreSQL RDS інстанс:
```hcl
module "postgres_rds" {
  source = "./modules/rds"
  
  use_aurora     = false
  engine         = "postgres"
  engine_version = "14.18"
  instance_class = "db.t3.micro"
  
  db_name  = "myapp"
  username = "dbadmin"
  password = "MySecretPassword123!"
  
  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = module.vpc.private_subnet_ids
  allowed_security_group_ids  = [aws_security_group.app.id]
  
  environment   = "dev"
  project_name  = "lesson-db-module"
}
```

### Aurora MySQL кластер:
```hcl
module "mysql_aurora" {
  source = "./modules/rds"
  
  use_aurora             = true
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.02.0"
  aurora_instance_class  = "db.r5.large"
  aurora_cluster_size    = 2
  
  db_name  = "webapp"
  username = "admin"
  password = "AuroraSecretPass123!"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  environment  = "production"
  project_name = "webapp"
}
```

---

## Опис змінних

### Обов'язкові змінні:
- `password` — пароль для бази даних (**sensitive**)
- `vpc_id` — ID VPC для розгортання
- `subnet_ids` — список ID підмереж для DB subnet group

### Основні змінні конфігурації:
- `use_aurora` — використовувати Aurora (`true`) чи RDS (`false`), *за замовчуванням*: `false`
- `engine` — двигун БД (`postgres`, `mysql`, `aurora-mysql`, `aurora-postgresql`), *за замовчуванням*: `postgres`
- `engine_version` — версія двигуна БД, *за замовчуванням*: `14.18`
- `instance_class` — клас інстансу для RDS, *за замовчуванням*: `db.t3.micro`
- `aurora_instance_class` — клас інстансу для Aurora, *за замовчуванням*: `db.r5.large`
- `db_name` — ім'я бази даних, *за замовчуванням*: `myapp`
- `username` — користувач БД, *за замовчуванням*: `dbadmin`

### Змінні продуктивності та безпеки:
- `multi_az` — Multi-AZ розгортання, *за замовчуванням*: `false`
- `storage_encrypted` — шифрування зберігання, *за замовчуванням*: `true`
- `backup_retention_period` — період збереження бекапів (дні), *за замовчуванням*: `7`
- `deletion_protection` — захист від видалення, *за замовчуванням*: `false`
- `performance_insights_enabled` — увімкнути Performance Insights, *за замовчуванням*: `false`

---

## Як змінити тип БД, engine, клас інстансу

### Зміна типу БД (RDS ↔ Aurora):
```hcl
# RDS інстанс
use_aurora = false
instance_class = "db.t3.micro"

# Aurora кластер
use_aurora = true
aurora_instance_class = "db.r5.large"
aurora_cluster_size = 2
```

### Зміна engine БД:
```hcl
# PostgreSQL
engine = "postgres"
engine_version = "14.18"

# MySQL RDS
engine = "mysql" 
engine_version = "8.0.35"

# Aurora MySQL
engine = "aurora-mysql"
engine_version = "8.0.mysql_aurora.3.02.0"

# Aurora PostgreSQL
engine = "aurora-postgresql"
engine_version = "14.7"
```

### Зміна класу інстансу:
```hcl
# Для розробки
instance_class = "db.t3.micro"           # RDS
aurora_instance_class = "db.t4g.medium"  # Aurora

# Для продакшена
instance_class = "db.r5.large"           # RDS
aurora_instance_class = "db.r5.xlarge"   # Aurora
```

---

## Налаштування продуктивності:
```hcl
# Високі навантаження
allocated_storage          = 500
max_allocated_storage      = 1000
storage_type               = "gp3"
multi_az                   = true
performance_insights_enabled = true
monitoring_interval        = 60
```

---

## Результати розгортання ✅
- ✅ PostgreSQL RDS створено  
  **Endpoint**: `lesson-db-module-dev-db.cdg82o4wqs1y.eu-west-1.rds.amazonaws.com:5432`
- ✅ Aurora PostgreSQL кластер успішно розгорнуто
