variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "git_repository_url" {
  description = "Git repository URL for applications"
  type        = string
}

variable "git_path" {
  description = "Path to Helm charts in Git repository"
  type        = string
  default     = "charts"
}

variable "target_revision" {
  description = "Git branch/tag to track"
  type        = string
  default     = "main"
}