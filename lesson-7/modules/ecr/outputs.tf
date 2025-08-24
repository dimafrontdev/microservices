output "repository_url" {
  description = "URL ECR репозиторію"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "repository_arn" {
  description = "ARN ECR репозиторію"
  value       = aws_ecr_repository.app_repo.arn
}

output "repository_name" {
  description = "Назва ECR репозиторію"
  value       = aws_ecr_repository.app_repo.name
}

output "registry_id" {
  description = "ID реєстру ECR"
  value       = aws_ecr_repository.app_repo.registry_id
}
