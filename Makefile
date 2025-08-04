.PHONY: up down clean dev-cluster apps-cluster help

# Default target
.DEFAULT_GOAL := help

# Variables
DEV_CLUSTER_NAME := dev-cluster
APPS_CLUSTER_NAME := apps-cluster
KUBECTL := kubectl
KIND := kind

help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: dev-cluster apps-cluster ## Start all local clusters

down: ## Stop all local clusters
	@echo "Deleting clusters..."
	$(KIND) delete cluster --name $(DEV_CLUSTER_NAME)
	$(KIND) delete cluster --name $(APPS_CLUSTER_NAME)
	@echo "Clusters deleted."

dev-cluster: ## Create the dev cluster
	@echo "Creating dev cluster..."
	$(KIND) create cluster --name $(DEV_CLUSTER_NAME) --config clusters/dev/kind.yaml
	@echo "Dev cluster created."
	@echo "Setting up Jenkins and monitoring..."
	$(KUBECTL) config use-context kind-$(DEV_CLUSTER_NAME)
	# Create Jenkins namespace
	$(KUBECTL) create namespace jenkins
	# Create ConfigMap for Jenkins Configuration as Code
	$(KUBECTL) create configmap jenkins-casc-config -n jenkins --from-file=jenkins.yaml=jenkins/jcasc/jenkins.yaml
	# Add Jenkins Helm repository if not already added
	helm repo add jenkins https://charts.jenkins.io
	helm repo update
	# Install Jenkins using Helm
	helm upgrade --install jenkins jenkins/jenkins -n jenkins -f jenkins/charts/values.yaml --wait
	@echo "Dev cluster setup complete."

apps-cluster: ## Create the apps cluster
	@echo "Creating apps cluster..."
	$(KIND) create cluster --name $(APPS_CLUSTER_NAME) --config clusters/apps/kind.yaml
	@echo "Apps cluster created."
	@echo "Setting up applications..."
	$(KUBECTL) config use-context kind-$(APPS_CLUSTER_NAME)
	@echo "Apps cluster setup complete."

clean: down ## Clean up all resources
	@echo "Cleaning up resources..."
	docker system prune -f
	@echo "Cleanup complete."

docker-build: ## Build all application Docker images
	@echo "Building Docker images..."
	cd apps/flask && docker build -t flask-app:latest .
	@echo "Docker build complete."

docker-push: ## Push Docker images to registry
	@echo "Pushing Docker images..."
	@echo "This would normally push to a registry like GHCR"
	@echo "Docker push complete."
