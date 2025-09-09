output "jenkins_url" {
  description = "Jenkins service URL"
  value       = try("http://${data.kubernetes_service.jenkins.status.0.load_balancer.0.ingress.0.hostname}", "LoadBalancer IP not ready")
  depends_on  = [helm_release.jenkins]
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = var.admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "${var.release_name}"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  depends_on = [helm_release.jenkins]
}