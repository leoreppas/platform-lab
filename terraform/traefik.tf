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

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  # Use YAML values (avoids set/set_list issues)
  values = [<<-YAML
    args:
      - --kubelet-insecure-tls
      - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
  YAML
  ]
}
