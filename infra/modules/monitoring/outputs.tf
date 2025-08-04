/**
 * # Monitoring Module Outputs
 *
 * This file defines the output values for the monitoring module.
 */

output "grafana_url" {
  description = "URL for Grafana dashboard"
  value       = var.enable_grafana && var.create_ingress ? "http://grafana.${var.cluster_name}.local" : "Grafana not enabled or Ingress not created"
}

output "prometheus_url" {
  description = "URL for Prometheus dashboard"
  value       = var.create_ingress ? "http://prometheus.${var.cluster_name}.local" : "Ingress not created"
}

output "alertmanager_url" {
  description = "URL for AlertManager dashboard"
  value       = var.enable_alertmanager && var.create_ingress ? "http://alertmanager.${var.cluster_name}.local" : "AlertManager not enabled or Ingress not created"
}

output "monitoring_namespace" {
  description = "Namespace where monitoring components are deployed"
  value       = local.monitoring_namespace
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = var.enable_grafana ? local.grafana_service_name : null
}

output "prometheus_service_name" {
  description = "Name of the Prometheus service"
  value       = local.prometheus_service_name
}

output "alertmanager_service_name" {
  description = "Name of the AlertManager service"
  value       = var.enable_alertmanager ? local.alertmanager_service_name : null
}

output "prometheus_stack_release_name" {
  description = "Name of the Helm release for kube-prometheus-stack"
  value       = helm_release.kube_prometheus_stack.name
}

output "prometheus_stack_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  value       = var.prometheus_stack_version
}
