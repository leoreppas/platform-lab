############################################
# HPA for whoami (v1)
############################################
resource "kubernetes_horizontal_pod_autoscaler_v2" "whoami" {
  metadata {
    name      = "whoami-hpa"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    min_replicas = 2
    max_replicas = 6

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.whoami.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type          = "AverageValue"
          average_value = "20Mi"
        }
      }
    }
  }
}

############################################
# HPA for whoami-v2
############################################
resource "kubernetes_horizontal_pod_autoscaler_v2" "whoami_v2" {
  metadata {
    name      = "whoami-v2-hpa"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    min_replicas = 2
    max_replicas = 6

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.whoami_v2.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type          = "AverageValue"
          average_value = "20Mi"
        }
      }
    }
  }
}
