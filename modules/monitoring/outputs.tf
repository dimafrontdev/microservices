output "prometheus_endpoint" {
  description = "Prometheus service endpoint"
  value       = "prometheus-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090"
}

output "grafana_endpoint" {
  description = "Grafana service endpoint"
  value       = "prometheus-grafana.${var.namespace}.svc.cluster.local"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "alertmanager_endpoint" {
  description = "AlertManager service endpoint"
  value       = "prometheus-kube-prometheus-alertmanager.${var.namespace}.svc.cluster.local:9093"
}

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = var.namespace
}