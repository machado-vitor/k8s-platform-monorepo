/**
 * # Provider Configuration
 *
 * This file configures the Kubernetes provider to use the dev-cluster context.
 */

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-dev-cluster"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-dev-cluster"
  }
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "kind-dev-cluster"
  load_config_file = true
}
