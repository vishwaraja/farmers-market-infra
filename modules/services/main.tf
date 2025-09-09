# =============================================================================
# KONG API GATEWAY MODULE
# =============================================================================
# This module deploys Kong API Gateway in the EKS cluster including:
# - Kong Ingress Controller
# - Kong Admin API
# - PostgreSQL database for Kong configuration
# - Kong configuration and routing

# Kong Namespace
resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
    labels = {
      name = "kong"
    }
  }
}

# Kong Database (PostgreSQL)
resource "kubernetes_deployment" "kong_database" {
  metadata {
    name      = "kong-database"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong-database"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kong-database"
      }
    }

    template {
      metadata {
        labels = {
          app = "kong-database"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:13"

          env {
            name  = "POSTGRES_DB"
            value = "kong"
          }

          env {
            name  = "POSTGRES_USER"
            value = "kong"
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.kong_database.metadata[0].name
                key  = "password"
              }
            }
          }

          port {
            container_port = 5432
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-storage"
          empty_dir {}
        }
      }
    }
  }
}

# Kong Database Service
resource "kubernetes_service" "kong_database" {
  metadata {
    name      = "kong-database"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong-database"
    }
  }

  spec {
    selector = {
      app = "kong-database"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

# Kong Database Secret
resource "kubernetes_secret" "kong_database" {
  metadata {
    name      = "kong-database"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    password = var.kong_database_password
  }

  type = "Opaque"
}

# Kong Migration Job
resource "kubernetes_job" "kong_migration" {
  metadata {
    name      = "kong-migration"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = {
          app = "kong-migration"
        }
      }

      spec {
        container {
          name  = "kong-migration"
          image = "kong:3.4"

          env {
            name  = "KONG_DATABASE"
            value = "postgres"
          }

          env {
            name  = "KONG_PG_HOST"
            value = kubernetes_service.kong_database.metadata[0].name
          }

          env {
            name  = "KONG_PG_DATABASE"
            value = "kong"
          }

          env {
            name  = "KONG_PG_USER"
            value = "kong"
          }

          env {
            name = "KONG_PG_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.kong_database.metadata[0].name
                key  = "password"
              }
            }
          }

          command = ["kong", "migrations", "bootstrap"]
        }

        restart_policy = "Never"
      }
    }
  }

  depends_on = [kubernetes_deployment.kong_database]
}

# Kong Ingress Controller Deployment
resource "kubernetes_deployment" "kong_ingress_controller" {
  metadata {
    name      = "kong-ingress-controller"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong-ingress-controller"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "kong-ingress-controller"
      }
    }

    template {
      metadata {
        labels = {
          app = "kong-ingress-controller"
        }
      }

      spec {
        container {
          name  = "kong-ingress-controller"
          image = "kong/kubernetes-ingress-controller:2.10"

          env {
            name  = "KONG_ADMIN_URL"
            value = "http://kong-admin:8001"
          }

          env {
            name  = "KONG_PROXY_URL"
            value = "http://kong-proxy:8000"
          }

          env {
            name  = "KONG_ADMIN_TLS_SKIP_VERIFY"
            value = "true"
          }

          env {
            name  = "KONG_PROXY_TLS_SKIP_VERIFY"
            value = "true"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_job.kong_migration]
}

# Kong Proxy Deployment
resource "kubernetes_deployment" "kong_proxy" {
  metadata {
    name      = "kong-proxy"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong-proxy"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "kong-proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "kong-proxy"
        }
      }

      spec {
        container {
          name  = "kong-proxy"
          image = "kong:3.4"

          env {
            name  = "KONG_DATABASE"
            value = "postgres"
          }

          env {
            name  = "KONG_PG_HOST"
            value = kubernetes_service.kong_database.metadata[0].name
          }

          env {
            name  = "KONG_PG_DATABASE"
            value = "kong"
          }

          env {
            name  = "KONG_PG_USER"
            value = "kong"
          }

          env {
            name = "KONG_PG_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.kong_database.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name  = "KONG_PROXY_ACCESS_LOG"
            value = "/dev/stdout"
          }

          env {
            name  = "KONG_ADMIN_ACCESS_LOG"
            value = "/dev/stdout"
          }

          env {
            name  = "KONG_PROXY_ERROR_LOG"
            value = "/dev/stderr"
          }

          env {
            name  = "KONG_ADMIN_ERROR_LOG"
            value = "/dev/stderr"
          }

          env {
            name  = "KONG_ADMIN_LISTEN"
            value = "0.0.0.0:8001"
          }

          env {
            name  = "KONG_PROXY_LISTEN"
            value = "0.0.0.0:8000"
          }

          port {
            container_port = 8000
            name           = "proxy"
          }

          port {
            container_port = 8001
            name           = "admin"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/status"
              port = 8001
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/status"
              port = 8001
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_job.kong_migration]
}

# Kong Proxy Service
resource "kubernetes_service" "kong_proxy" {
  metadata {
    name      = "kong-proxy"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong-proxy"
    }
  }

  spec {
    selector = {
      app = "kong-proxy"
    }

    port {
      name        = "proxy"
      port        = 80
      target_port = 8000
    }

    port {
      name        = "admin"
      port        = 8001
      target_port = 8001
    }

    type = "LoadBalancer"
  }
}

# Kong Admin Service
resource "kubernetes_service" "kong_admin" {
  metadata {
    name      = "kong-admin"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong-proxy"
    }
  }

  spec {
    selector = {
      app = "kong-proxy"
    }

    port {
      name        = "admin"
      port        = 8001
      target_port = 8001
    }

    type = "ClusterIP"
  }
}

# Kong Ingress for ALB Integration
resource "kubernetes_ingress_v1" "kong_ingress" {
  metadata {
    name      = "kong-ingress"
    namespace = kubernetes_namespace.kong.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{HTTP = 80}, {HTTPS = 443}])
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/status"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.kong_proxy.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}

# Kong Configuration ConfigMap
resource "kubernetes_config_map" "kong_config" {
  metadata {
    name      = "kong-config"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    "kong.yml" = templatefile("${path.module}/templates/kong.yml.tpl", {
      services = var.kong_services
    })
  }
}

# Kong RBAC
resource "kubernetes_cluster_role" "kong_ingress_controller" {
  metadata {
    name = "kong-ingress-controller"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }
}

resource "kubernetes_cluster_role_binding" "kong_ingress_controller" {
  metadata {
    name = "kong-ingress-controller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kong_ingress_controller.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kong_ingress_controller.metadata[0].name
    namespace = kubernetes_namespace.kong.metadata[0].name
  }
}

resource "kubernetes_service_account" "kong_ingress_controller" {
  metadata {
    name      = "kong-ingress-controller"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }
}
