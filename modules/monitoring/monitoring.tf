resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "51.3.0"

  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention    = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
        }
        service = {
          type = "ClusterIP"
        }
      }
      
      grafana = {
        enabled = true
        adminPassword = var.grafana_admin_password
        service = {
          type = "ClusterIP"
        }
        persistence = {
          enabled = true
          size = "5Gi"
          storageClassName = "gp2"
        }
        sidecar = {
          datasources = {
            enabled = true
            defaultDatasourceEnabled = true
          }
          dashboards = {
            enabled = true
          }
        }
      }
      
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          }
        }
      }
      
      kubeStateMetrics = {
        enabled = true
      }
      
      nodeExporter = {
        enabled = true
      }
      
      prometheusOperator = {
        enabled = true
      }
    })
  ]

  depends_on = [var.eks_cluster_ready]
}

# Service Monitor будет создан позже через kubectl или Helm
# resource "kubernetes_manifest" "django_service_monitor" {
#   manifest = {
#     apiVersion = "monitoring.coreos.com/v1"
#     kind       = "ServiceMonitor"
#     metadata = {
#       name      = "django-app-monitor"
#       namespace = var.namespace
#       labels = {
#         app = "django-app"
#       }
#     }
#     spec = {
#       selector = {
#         matchLabels = {
#           app = "django-app"
#         }
#       }
#       endpoints = [
#         {
#           port = "http"
#           path = "/metrics"
#         }
#       ]
#     }
#   }
#
#   depends_on = [helm_release.prometheus]
# }