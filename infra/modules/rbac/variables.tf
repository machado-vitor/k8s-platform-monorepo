/**
 * # RBAC Module Variables
 *
 * This file defines the input variables for the RBAC module.
 */

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where roles will be created"
  type        = string
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace where Jenkins is deployed"
  type        = string
  default     = "jenkins"
}

variable "service_account_name" {
  description = "Name of the Jenkins service account"
  type        = string
  default     = "jenkins"
}

variable "create_service_account" {
  description = "Whether to create the Jenkins service account"
  type        = bool
  default     = false
}

variable "service_account_annotations" {
  description = "Annotations to add to the Jenkins service account"
  type        = map(string)
  default     = {}
}

variable "create_cluster_admin" {
  description = "Whether to create a cluster admin role binding"
  type        = bool
  default     = false
}

variable "create_edit_role" {
  description = "Whether to create an edit role in the specified namespace"
  type        = bool
  default     = true
}

variable "create_view_role" {
  description = "Whether to create a view role in the specified namespace"
  type        = bool
  default     = true
}

variable "create_namespaced_roles" {
  description = "List of namespaces to create role bindings in"
  type        = list(string)
  default     = ["default"]
}

variable "additional_role_rules" {
  description = "Additional rules to add to the Jenkins role"
  type = list(object({
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  }))
  default = []
}
