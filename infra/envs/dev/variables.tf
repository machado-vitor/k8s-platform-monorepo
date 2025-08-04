/**
 * # Input Variables
 *
 * This file defines the input variables for the dev environment.
 */

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "admin"  # Should be overridden in a secure way
}

variable "alertmanager_slack_webhook" {
  description = "Slack webhook URL for AlertManager notifications"
  type        = string
  sensitive   = true
  default     = ""  # Should be provided in a secure way
}

variable "prometheus_storage_class" {
  description = "Storage class to use for Prometheus"
  type        = string
  default     = "standard"
}

variable "enable_alertmanager" {
  description = "Whether to enable AlertManager"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Whether to enable Grafana"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "jenkins_service_account_annotations" {
  description = "Annotations to add to the Jenkins service account"
  type        = map(string)
  default     = {}
}

variable "rbac_create_cluster_admin" {
  description = "Whether to create a cluster admin role binding"
  type        = bool
  default     = false
}

variable "rbac_create_namespaced_roles" {
  description = "List of namespaces to create role bindings in"
  type        = list(string)
  default     = ["default", "kube-system"]
}
