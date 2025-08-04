/**
 * # Jenkins RBAC Configuration
 *
 * This module creates the necessary RBAC resources for Jenkins to interact with the Kubernetes cluster.
 * It includes:
 * - Service Account for Jenkins
 * - Role and RoleBinding for namespace-scoped access
 * - ClusterRole and ClusterRoleBinding for cluster-wide access (optional)
 */

# Local variables
locals {
  jenkins_namespace = var.jenkins_namespace
  service_account_name = var.service_account_name
  namespaced_roles = var.create_namespaced_roles
}

# Create a service account for Jenkins if it doesn't exist
resource "kubernetes_service_account" "jenkins" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name = local.service_account_name
    namespace = local.jenkins_namespace

    labels = {
      app = "jenkins"
      environment = var.environment
    }

    annotations = var.service_account_annotations
  }
}

# Create a cluster role for Jenkins with admin permissions
resource "kubernetes_cluster_role" "jenkins_admin" {
  count = var.create_cluster_admin ? 1 : 0

  metadata {
    name = "jenkins-admin"

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# Bind the cluster role to the Jenkins service account
resource "kubernetes_cluster_role_binding" "jenkins_admin" {
  count = var.create_cluster_admin ? 1 : 0

  metadata {
    name = "jenkins-admin-binding"

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins_admin[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = local.jenkins_namespace
  }
}

# Create a role for Jenkins with edit permissions in specific namespaces
resource "kubernetes_role" "jenkins_edit" {
  count = var.create_edit_role ? 1 : 0

  metadata {
    name = "jenkins-edit"
    namespace = var.namespace

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  rule {
    api_groups = ["", "apps", "batch", "extensions"]
    resources  = ["*"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }
}

# Bind the edit role to the Jenkins service account
resource "kubernetes_role_binding" "jenkins_edit" {
  count = var.create_edit_role ? 1 : 0

  metadata {
    name = "jenkins-edit-binding"
    namespace = var.namespace

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.jenkins_edit[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = local.jenkins_namespace
  }
}

# Create a role for Jenkins with view permissions in specific namespaces
resource "kubernetes_role" "jenkins_view" {
  count = var.create_view_role ? 1 : 0

  metadata {
    name = "jenkins-view"
    namespace = var.namespace

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  rule {
    api_groups = ["", "apps", "batch", "extensions", "networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

# Bind the view role to the Jenkins service account
resource "kubernetes_role_binding" "jenkins_view" {
  count = var.create_view_role ? 1 : 0

  metadata {
    name = "jenkins-view-binding"
    namespace = var.namespace

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.jenkins_view[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = local.jenkins_namespace
  }
}

# Create namespaced role bindings for existing roles
resource "kubernetes_role_binding" "jenkins_namespaced" {
  for_each = toset(local.namespaced_roles)

  metadata {
    name = "jenkins-${each.value}-binding"
    namespace = each.value

    labels = {
      app = "jenkins"
      environment = var.environment
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"  # Use the built-in edit role
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = local.jenkins_namespace
  }
}
