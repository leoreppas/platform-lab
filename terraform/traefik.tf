resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = "traefik"
  create_namespace = true

  # Service type and NodePort mapping (matches kind extraPortMappings -> host 80/443)
  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "service.spec.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "ports.web.nodePort"
    value = "30080"
  }

  set {
    name  = "ports.websecure.nodePort"
    value = "30443"
  }
}

