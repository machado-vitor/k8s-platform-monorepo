/**
 * # RBAC Module Outputs
 *
 * This file defines the output values for the RBAC module.
 */

output "service_account_name" {
  description = "Name of the Jenkins service account"
  value       = local.service_account_name
}

output "jenkins_namespace" {
  description = "Namespace where Jenkins is deployed"
  value       = local.jenkins_namespace
}

output "cluster_admin_role_name" {
  description = "Name of the cluster admin role"
  value       = var.create_cluster_admin ? kubernetes_cluster_role.jenkins_admin[0].metadata[0].name : null
}

output "edit_role_name" {
  description = "Name of the edit role"
  value       = var.create_edit_role ? kubernetes_role.jenkins_edit[0].metadata[0].name : null
}

output "view_role_name" {
  description = "Name of the view role"
  value       = var.create_view_role ? kubernetes_role.jenkins_view[0].metadata[0].name : null
}

output "namespaced_role_bindings" {
  description = "Map of namespaces to role binding names"
  value       = {
    for ns in local.namespaced_roles :
    ns => "jenkins-${ns}-binding"
  }
}

output "has_cluster_admin" {
  description = "Whether Jenkins has cluster admin permissions"
  value       = var.create_cluster_admin
}

output "has_edit_role" {
  description = "Whether Jenkins has edit permissions in the specified namespace"
  value       = var.create_edit_role
}

output "has_view_role" {
  description = "Whether Jenkins has view permissions in the specified namespace"
  value       = var.create_view_role
}
