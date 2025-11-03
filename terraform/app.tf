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
        # / -> v1
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.whoami.metadata[0].name
              port { number = 80 }
            }
          }
        }
        # /v2 -> v2
        path {
          path      = "/v2"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.whoami_v2.metadata[0].name
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
