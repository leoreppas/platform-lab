############################################
# app.tf — demo namespace, v1 + v2, ingress
############################################

# Namespace
resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

# -------------------------
# whoami v1 (replicas = 3)
# -------------------------
resource "kubernetes_deployment" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = {
      app = "whoami"
    }
  }

  spec {
    replicas = 3
    revision_history_limit = 2

    selector {
      match_labels = {
        app = "whoami"
      }
    }

    # Deployment-level strategy
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    template {
      metadata {
        labels = {
          app = "whoami"
        }
      }

      spec {
        container {
          name  = "whoami"
          image = "traefik/whoami:latest"

          port { container_port = 80 }

          liveness_probe {
            http_get { 
              path = "/" 
              port = 80 
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          readiness_probe {
            http_get { 
              path = "/" 
              port = 80 
            }
            initial_delay_seconds = 2
            period_seconds        = 5
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = { app = "whoami" }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
}

# -------------------------
# whoami v2 (replicas = 2)
# -------------------------
resource "kubernetes_deployment" "whoami_v2" {
  metadata {
    name      = "whoami-v2" # k8s name may have a hyphen
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = {
      app = "whoami-v2"
    }
  }

  spec {
    replicas = 2
    revision_history_limit = 2

    selector {
      match_labels = {
        app = "whoami-v2"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    template {
      metadata {
        labels = {
          app = "whoami-v2"
        }
      }

      spec {
        container {
          name  = "whoami-v2"
          image = "traefik/whoami:latest"

          port { 
            container_port = 80 
          }

          liveness_probe {
            http_get { 
              path = "/" 
              port = 80 
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          readiness_probe {
            http_get { 
              path = "/" 
              port = 80 
            }
            initial_delay_seconds = 2
            period_seconds        = 5
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami_v2" {
  metadata {
    name      = "whoami-v2"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = { 
      app = "whoami-v2" 
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
}

# -------------------------
# Ingress (Traefik)
# -------------------------
resource "kubernetes_ingress_v1" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    ingress_class_name = "traefik"
    rule {
      host = "localhost"
      http {
        # / -> v2 (new default)
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.whoami_v2.metadata[0].name
              port { number = 80 }
            }
          }
        }

        # /v1 -> old service
        path {
          path      = "/v1"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.whoami.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }

  # ensure Traefik is installed first (defined in traefik.tf)
  depends_on = [helm_release.traefik]
}

resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    pod_selector {}  
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy_v1" "allow_from_traefik" {
  metadata {
    name      = "allow-from-traefik"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    pod_selector {
      match_expressions {
        key = "app"
        operator = "In"
        values = ["whoami", "whoami-v2"]
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
          }
        }

        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "traefik"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 80
      }
    }
  }
}


# -------------------------
# PodDistributionBudgets
# -------------------------
resource "kubernetes_pod_disruption_budget_v1" "whoami" {
  metadata {
    name      = "whoami-pdb"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }
  spec {
    min_available = 1
    selector {
      match_labels = {
        app = "whoami"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "whoami_v2" {
  metadata {
    name      = "whoami-v2-pdb"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }
  spec {
    min_available = 1
    selector {
      match_labels = {
        app = "whoami-v2"
      }
    }
  }
}
