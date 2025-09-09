resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY_ID     = ""
    AWS_SECRET_ACCESS_KEY = ""
  }
}

resource "kubernetes_config_map" "jenkins_config" {
  metadata {
    name      = "jenkins-config"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    ECR_REGION         = var.ecr_region
    ECR_REPOSITORY_URL = var.ecr_repository_url
    CLUSTER_NAME       = var.cluster_name
  }
}

resource "helm_release" "jenkins" {
  name       = var.release_name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "controller.adminUser"
    value = var.admin_user
  }

  set_sensitive {
    name  = "controller.adminPassword"
    value = var.admin_password
  }

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_secret.aws_credentials,
    kubernetes_config_map.jenkins_config
  ]
}