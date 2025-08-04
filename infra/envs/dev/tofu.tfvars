# Default values for dev environment
# This file should not contain sensitive information in a real environment

# Grafana configuration
grafana_admin_password = "admin"  # Should be overridden in a secure way

# AlertManager configuration
alertmanager_slack_webhook = ""  # Should be provided in a secure way
enable_alertmanager = true

# Prometheus configuration
prometheus_storage_class = "standard"

# Component enablement
enable_grafana = true

# Namespace configuration
monitoring_namespace = "monitoring"

# Jenkins RBAC configuration
jenkins_service_account_annotations = {
  "example.com/annotation" = "value"
}

rbac_create_cluster_admin = false
rbac_create_namespaced_roles = [
  "default",
  "kube-system",
  "monitoring",
  "platform"
]
