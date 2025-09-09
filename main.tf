provider "aws" {
  region = "eu-west-1"
}

# S3 Backend for Terraform state
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "final-project-bucket-${random_id.bucket_suffix.hex}"
  table_name  = "terraform-locks"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# VPC Infrastructure
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_name           = "final-project-vpc"
}

# ECR Repository
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "final-project-ecr"
  scan_on_push = true
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"
  
  cluster_name     = "final-project-eks-cluster"
  cluster_version  = "1.28"
  
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  node_group_name     = "final-project-nodes"
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_max_size       = 4
  node_min_size       = 1
}

# RDS PostgreSQL Database
module "postgres_rds" {
  source = "./modules/rds"
  
  # Basic Configuration
  use_aurora     = false
  engine         = "postgres"
  engine_version = "14.18"
  instance_class = "db.t3.micro"
  
  # Database Configuration
  db_name  = "djangodb"
  username = "dbadmin"
  password = "MySecretPassword123!"
  
  # Network Configuration
  vpc_id                        = module.vpc.vpc_id
  subnet_ids                   = module.vpc.private_subnet_ids
  allowed_security_group_ids   = [module.eks.cluster_security_group_id]
  
  # Environment
  environment   = "production"
  project_name  = "final-project"
  
  # Storage Configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  
  # Backup Configuration
  backup_retention_period = 7
  skip_final_snapshot    = false
  
  # High Availability for production
  multi_az = true
  
  tags = {
    Type = "PostgreSQL"
    Team = "DevOps"
    Environment = "Production"
  }
}

# Jenkins for CI/CD
module "jenkins" {
  source = "./modules/jenkins"
  
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  
  namespace            = "jenkins"
  release_name         = "jenkins"
  admin_user          = "admin"
  admin_password      = "admin123"
  ecr_repository_url  = module.ecr.ecr_url
  ecr_region          = "eu-west-1"
}

# Argo CD for GitOps
module "argo_cd" {
  source = "./modules/argo_cd"
  
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  
  namespace          = "argocd"
  release_name       = "argocd"
  git_repository_url = "https://github.com/your-username/final-project"
  git_path          = "charts"
  target_revision   = "main"
}

# Monitoring Stack (Prometheus + Grafana)
module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  
  namespace = "monitoring"
  grafana_admin_password = "admin123"
  
  eks_cluster_ready = module.eks.cluster_id
}