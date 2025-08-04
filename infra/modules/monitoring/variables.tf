/**
 * # Monitoring Module Variables
 *
 * This file defines the input variables for the monitoring module.
 */

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "create_ingress" {
  description = "Whether to create Ingress resources"
  type        = bool
  default     = true
}

# Prometheus configuration
variable "prometheus_retention_time" {
  description = "Retention time for Prometheus data"
  type        = string
  default     = "7d"
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus PVCs"
  type        = string
  default     = "standard"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus PVCs"
  type        = string
  default     = "10Gi"
}

variable "prometheus_stack_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = "45.7.1"  # Update to the latest version as needed
}

# Grafana configuration
variable "enable_grafana" {
  description = "Whether to enable Grafana"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "admin"
}

# AlertManager configuration
variable "enable_alertmanager" {
  description = "Whether to enable AlertManager"
  type        = bool
  default     = true
}

variable "alertmanager_slack_webhook" {
  description = "Slack webhook URL for AlertManager notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_slack_channel" {
  description = "Slack channel for AlertManager notifications"
  type        = string
  default     = "#alerts"
}

# Additional configuration
variable "additional_scrape_configs" {
  description = "Additional scrape configurations for Prometheus"
  type        = list(any)
  default     = []
}

variable "node_exporter_enabled" {
  description = "Whether to enable Node Exporter"
  type        = bool
  default     = true
}

variable "kube_state_metrics_enabled" {
  description = "Whether to enable Kube State Metrics"
  type        = bool
  default     = true
}
