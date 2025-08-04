/**
 * # Dev Environment Infrastructure
 *
 * This Terraform/OpenTofu configuration deploys infrastructure components for the dev environment.
 * It includes monitoring and RBAC configurations.
 */

# Local variables
locals {
  environment = "dev"
  cluster_name = "dev-cluster"
  namespace = "platform"
}

# Create namespace for platform components
resource "kubernetes_namespace" "platform" {
  metadata {
    name = local.namespace

    labels = {
      environment = local.environment
      managed-by = "terraform"
    }
  }
}

# Deploy monitoring stack
module "monitoring" {
  source = "../../modules/monitoring"

  environment = local.environment
  namespace = kubernetes_namespace.platform.metadata[0].name
  cluster_name = local.cluster_name

  # Grafana configuration
  grafana_admin_password = var.grafana_admin_password

  # Prometheus configuration
  prometheus_retention_time = "7d"
  prometheus_storage_size = "10Gi"

  # AlertManager configuration
  alertmanager_slack_webhook = var.alertmanager_slack_webhook
  alertmanager_slack_channel = "#${local.environment}-alerts"

  depends_on = [
    kubernetes_namespace.platform
  ]
}

# Deploy RBAC configuration for Jenkins
module "rbac" {
  source = "../../modules/rbac"

  environment = local.environment
  namespace = kubernetes_namespace.platform.metadata[0].name
  jenkins_namespace = "jenkins"

  # Service account for Jenkins
  service_account_name = "jenkins"

  # Cluster role bindings
  create_cluster_admin = false
  create_edit_role = true
  create_view_role = true

  depends_on = [
    kubernetes_namespace.platform
  ]
}

# Output values
output "grafana_url" {
  description = "URL for Grafana dashboard"
  value = module.monitoring.grafana_url
}

output "prometheus_url" {
  description = "URL for Prometheus dashboard"
  value = module.monitoring.prometheus_url
}

output "alertmanager_url" {
  description = "URL for AlertManager dashboard"
  value = module.monitoring.alertmanager_url
}
