# Infrastructure Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# ECR Output
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.ecr_url
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

# Database Outputs
output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.postgres_rds.database_endpoint
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = module.postgres_rds.database_port
}

# Jenkins Outputs
output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

# Argo CD Outputs
output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = module.argo_cd.argocd_namespace
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password"
  value       = module.argo_cd.argocd_admin_password
  sensitive   = true
}

# Monitoring Outputs
output "prometheus_endpoint" {
  description = "Prometheus endpoint"
  value       = module.monitoring.prometheus_endpoint
}

output "grafana_endpoint" {
  description = "Grafana endpoint"
  value       = module.monitoring.grafana_endpoint
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

# Connection Commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region eu-west-1 --name ${module.eks.cluster_name}"
}

output "jenkins_port_forward_command" {
  description = "Command to access Jenkins"
  value       = "kubectl port-forward svc/jenkins 8080:8080 -n jenkins"
}

output "argocd_port_forward_command" {
  description = "Command to access Argo CD"
  value       = "kubectl port-forward svc/argocd-server 8081:443 -n argocd"
}

output "grafana_port_forward_command" {
  description = "Command to access Grafana"
  value       = "kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
}