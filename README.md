# platform-lab

## This project is a hands-on lab environment designed to practice real-world Platform Engineering and DevOps workflows using:
- Kubernetes
- Terraform
- Helm
- Modern platform reliability patterns

## Stack
| Component                        | Purpose                                      |
| -------------------------------- | -------------------------------------------- |
| [kind](https://kind.sigs.k8s.io) | Local Kubernetes cluster                     |
| Terraform                        | Declarative platform infra (K8s + Helm)      |
| Helm                             | Package deployment (Traefik, metrics-server) |
| Traefik                          | Ingress controller                           |
| whoami services                  | Test workload (v1 & v2 variants)             |
| metrics-server                   | Enables autoscaling (`kubectl top`, HPA)     |

## Architecture
```text
┌──────────────────────────────────────────────┐
│                  kind Cluster                │
│             (local Kubernetes)               │
│                                              │
│  ┌────────────── Ingress (Traefik) ─────────┐│
│  │ Host: localhost                          ││
│  │                                          ││
│  │ /    ──► whoami (v1) Deployment          ││
│  │ /v1  ──► whoami (v1) Deployment          ││
│  │ /v2  ──► whoami (v2) Deployment          ││
│  └──────────────────────────────────────────┘│
│                                              │
│  Deployments & Services                      │
│   • whoami (v1)                              │
│       └─ ClusterIP, HPA (2–6 replicas)       │
│   • whoami-v2                                │
│       └─ ClusterIP, HPA (2–6 replicas)       │
│                                              │
│  Reliability Controls                        │
│   • Liveness & Readiness probes              │
│   • PodDisruptionBudgets                     │
│   • RollingUpdate (maxUnavailable = 0)       │
│   • NetworkPolicies (default deny)           │
│   • Resource requests & limits               │
└──────────────────────────────────────────────┘
```

## How to run
1) Start the cluster
kind create cluster --config kind-cluster.yaml

2) Deploy platform + apps
cd terraform
terraform init
terraform apply -auto-approve

3) Test traffic
curl http://localhost/     # v1
curl http://localhost/v2   # v2

4) Check autoscaling and metrics
kubectl top nodes
kubectl -n demo top pods
kubectl -n demo get hpa

## Cleanup
terraform destroy -auto-approve
kind delete cluster --name platform-lab
