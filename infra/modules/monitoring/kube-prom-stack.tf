/**
 * # Kube Prometheus Stack
 *
 * This module deploys the kube-prometheus-stack Helm chart, which includes:
 * - Prometheus
 * - Grafana
 * - AlertManager
 * - Node Exporter
 * - Kube State Metrics
 */

# Local variables
locals {
  monitoring_namespace = var.namespace
  grafana_service_name = "grafana"
  prometheus_service_name = "prometheus-server"
  alertmanager_service_name = "alertmanager"
}

# Create namespace if it doesn't exist
resource "kubernetes_namespace" "monitoring" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = local.monitoring_namespace

    labels = {
      name = local.monitoring_namespace
      environment = var.environment
      "kubernetes.io/metadata.name" = local.monitoring_namespace
    }
  }
}

# Deploy kube-prometheus-stack Helm chart
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_stack_version
  namespace  = local.monitoring_namespace

  # Wait for the namespace to be created
  depends_on = [kubernetes_namespace.monitoring]

  # Set timeout for Helm operations
  timeout = 600

  # Basic configuration values
  set {
    name  = "fullnameOverride"
    value = "prometheus"
  }

  # Prometheus configuration
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention_time
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.prometheus_storage_class
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Grafana configuration
  set {
    name  = "grafana.enabled"
    value = var.enable_grafana
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }

  # AlertManager configuration
  set {
    name  = "alertmanager.enabled"
    value = var.enable_alertmanager
  }

  set {
    name  = "alertmanager.config.global.slack_api_url"
    value = var.alertmanager_slack_webhook
  }

  # Configure Slack receiver if webhook is provided
  set {
    name  = "alertmanager.config.receivers[0].name"
    value = "slack-notifications"
  }

  set {
    name  = "alertmanager.config.receivers[0].slack_configs[0].channel"
    value = var.alertmanager_slack_channel
  }

  set {
    name  = "alertmanager.config.route.receiver"
    value = "slack-notifications"
  }

  # Node exporter configuration
  set {
    name  = "prometheus-node-exporter.enabled"
    value = true
  }

  # Kube state metrics configuration
  set {
    name  = "kube-state-metrics.enabled"
    value = true
  }
}

# Create Ingress for Grafana if enabled
resource "kubernetes_ingress_v1" "grafana_ingress" {
  count = var.enable_grafana && var.create_ingress ? 1 : 0

  metadata {
    name      = "grafana-ingress"
    namespace = local.monitoring_namespace

    annotations = {
      "spec.ingressClassName" = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    rule {
      host = "grafana.${var.cluster_name}.local"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = local.grafana_service_name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# Create Ingress for Prometheus if enabled
resource "kubernetes_ingress_v1" "prometheus_ingress" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = "prometheus-ingress"
    namespace = local.monitoring_namespace

    annotations = {
      "spec.ingressClassName" = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    rule {
      host = "prometheus.${var.cluster_name}.local"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = local.prometheus_service_name
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# Create Ingress for AlertManager if enabled
resource "kubernetes_ingress_v1" "alertmanager_ingress" {
  count = var.enable_alertmanager && var.create_ingress ? 1 : 0

  metadata {
    name      = "alertmanager-ingress"
    namespace = local.monitoring_namespace

    annotations = {
      "spec.ingressClassName" = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    rule {
      host = "alertmanager.${var.cluster_name}.local"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = local.alertmanager_service_name
              port {
                number = 9093
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
