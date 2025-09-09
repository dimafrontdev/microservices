output "argocd_url" {
  description = "Argo CD server URL"
  value       = try("https://${data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress.0.hostname}", "LoadBalancer IP not ready")
  depends_on  = [helm_release.argocd]
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password"
  value       = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
  sensitive   = true
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_admin_user" {
  description = "Argo CD admin username"
  value       = "admin"
}