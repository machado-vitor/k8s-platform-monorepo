#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to print section headers
print_section() {
  echo -e "\n${GREEN}==== $1 ====${NC}\n"
}

# Function to print errors
print_error() {
  echo -e "${RED}ERROR: $1${NC}"
}

# Function to print warnings
print_warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}$1${NC}"
}

# Check prerequisites
check_prerequisites() {
  print_section "Checking Prerequisites"

  local missing_tools=()

  # Check for Docker
  if ! command_exists docker; then
    missing_tools+=("Docker")
  else
    print_success "✓ Docker is installed"
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
      print_error "Docker daemon is not running. Please start Docker and try again."
      exit 1
    fi
  fi

  # Check for kubectl
  if ! command_exists kubectl; then
    missing_tools+=("kubectl")
  else
    print_success "✓ kubectl is installed"
  fi

  # Check for kind
  if ! command_exists kind; then
    missing_tools+=("kind")
  else
    print_success "✓ kind is installed"
  fi

  # Check for Helm
  if ! command_exists helm; then
    missing_tools+=("Helm")
  else
    print_success "✓ Helm is installed"
  fi

  # Check for OpenTofu/Terraform
  if ! command_exists terraform && ! command_exists tofu; then
    missing_tools+=("OpenTofu/Terraform")
    print_warning "Neither OpenTofu nor Terraform is installed"
  else
    print_success "✓ OpenTofu/Terraform is installed"
  fi

  # If any tools are missing, print error and exit
  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_error "The following required tools are missing:"
    for tool in "${missing_tools[@]}"; do
      echo "  - $tool"
    done
    echo -e "\nPlease install the missing tools and try again."
    exit 1
  fi
}

# Set up the development environment
setup_environment() {
  print_section "Setting Up Development Environment"

  # Clean up any existing clusters
  print_warning "Cleaning up any existing clusters..."
  make down

  # Start the clusters
  print_success "Starting clusters..."
  make dev-cluster
  make apps-cluster

  # Build Docker images
  print_success "Building Docker images..."
  make docker-build
}

# Deploy Jenkins
deploy_jenkins() {
  print_section "Deploying Jenkins"

  # Check if dev cluster exists
  if ! kind get clusters | grep -q "^dev-cluster$"; then
    print_warning "Dev cluster does not exist. Creating it now..."
    make dev-cluster
  fi

  # Switch to dev cluster
  if ! kubectl config use-context kind-dev-cluster 2>/dev/null; then
    print_error "Failed to switch to dev-cluster context. Ensure the cluster is created properly."
    return 1
  fi

  # Install NGINX Ingress Controller if not already installed
  if ! kubectl get deployment -n ingress-nginx ingress-nginx-controller 2>/dev/null; then
    print_success "Installing NGINX Ingress Controller..."
    kubectl create namespace ingress-nginx 2>/dev/null
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --set controller.service.type=NodePort \
      --set controller.service.nodePorts.http=30081 \
      --set controller.service.nodePorts.https=30444 \
      --wait
  fi

  # Create Jenkins namespace if it doesn't exist
  kubectl create namespace jenkins 2>/dev/null

  # Apply RBAC configuration for Jenkins
  print_success "Applying Jenkins RBAC configuration..."
  kubectl apply -f jenkins/rbac.yaml

  # Create ConfigMap for Jenkins Configuration as Code
  print_success "Creating Jenkins Configuration as Code ConfigMap..."
  kubectl create configmap jenkins-casc-config -n jenkins --from-file=jenkins.yaml=jenkins/jcasc/jenkins.yaml --dry-run=client -o yaml | kubectl apply -f -

  # Add Jenkins Helm repository if not already added
  helm repo add jenkins https://charts.jenkins.io
  helm repo update

  # Update Jenkins Helm values to match cluster configuration
  print_success "Deploying Jenkins..."
  cat <<EOF > /tmp/jenkins-values-override.yaml
controller:
  serviceType: NodePort
  servicePort: 8080
  jenkinsUrl: "http://jenkins.local"
  serviceNodePort: 30082
  ingress:
    enabled: true
    apiVersion: "networking.k8s.io/v1"
    hostName: "jenkins.local"
    annotations:
      spec.ingressClassName: nginx
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
EOF

  # Install Jenkins using Helm with overridden values
  helm upgrade --install jenkins jenkins/jenkins \
    -n jenkins \
    -f jenkins/charts/values.yaml \
    -f /tmp/jenkins-values-override.yaml \
    --wait --timeout 5m

  # Wait for Jenkins to be ready
  print_success "Waiting for Jenkins to be ready..."
  kubectl rollout status deployment/jenkins -n jenkins --timeout=300s

  # Verify Jenkins is running
  if kubectl get pods -n jenkins -l app.kubernetes.io/component=jenkins-controller -o jsonpath='{.items[0].status.phase}' | grep -q "Running"; then
    print_success "Jenkins is running!"

    # Get Jenkins admin password
    JENKINS_PASSWORD=$(kubectl exec -n jenkins $(kubectl get pods -n jenkins -l app.kubernetes.io/component=jenkins-controller -o jsonpath='{.items[0].metadata.name}') -- cat /run/secrets/additional/chart-admin-password 2>/dev/null || echo "admin")
    print_success "Jenkins admin password: ${JENKINS_PASSWORD}"
  else
    print_error "Jenkins is not running. Check the logs with: kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller"
    # Print the logs for debugging
    kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller
  fi
}

# Deploy applications
deploy_applications() {
  print_section "Deploying Applications"

  # Check if apps cluster exists
  if ! kind get clusters | grep -q "^apps-cluster$"; then
    print_warning "Apps cluster does not exist. Creating it now..."
    make apps-cluster
  fi

  # Switch to apps cluster
  if ! kubectl config use-context kind-apps-cluster 2>/dev/null; then
    print_error "Failed to switch to apps-cluster context. Ensure the cluster is created properly."
    return 1
  fi

  # Install NGINX Ingress Controller if not already installed
  if ! kubectl get deployment -n ingress-nginx ingress-nginx-controller 2>/dev/null; then
    print_success "Installing NGINX Ingress Controller..."
    kubectl create namespace ingress-nginx 2>/dev/null
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --set controller.service.type=NodePort \
      --set controller.service.nodePorts.http=30080 \
      --set controller.service.nodePorts.https=30443 \
      --wait
  fi

  # Check if Flask app is already deployed
  if kubectl get deployment flask-app -n flask 2>/dev/null; then
    print_warning "Flask app is already deployed. Redeploying..."
    kubectl delete deployment flask-app -n flask
  fi

  print_success "Deploying Flask app..."

  # Create namespace if it doesn't exist
  kubectl create namespace flask 2>/dev/null

  # Build and load the Docker image into kind
  docker build -t flask-app:latest ./apps/flask/
  kind load docker-image flask-app:latest --name apps-cluster

  # Create a deployment and service for the Flask app
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  namespace: flask
  labels:
    app: flask-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-app
        image: flask-app:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
        env:
        - name: PORT
          value: "5000"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: flask-app
  namespace: flask
spec:
  selector:
    app: flask-app
  ports:
  - port: 80
    targetPort: 5000
    nodePort: 30001
  type: NodePort
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-app
  namespace: flask
  annotations:
    spec.ingressClassName: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: flask-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-app
            port:
              number: 80
EOF

  # Wait for Flask app to be ready
  print_success "Waiting for Flask app to be ready..."
  kubectl rollout status deployment/flask-app -n flask --timeout=120s

  # Verify Flask app is running
  if kubectl get pods -n flask -l app=flask-app -o jsonpath='{.items[0].status.phase}' | grep -q "Running"; then
    print_success "Flask app is running!"
  else
    print_error "Flask app is not running. Check the logs with: kubectl logs -n flask -l app=flask-app"
    # Print the logs for debugging
    kubectl logs -n flask -l app=flask-app
  fi
}

# Print access information
print_access_info() {
  print_section "Access Information"

  echo "Dev Cluster:"
  echo "  - API Server: https://127.0.0.1:6443"
  echo "  - Jenkins: http://localhost:30082"
  echo "  - Jenkins Ingress: http://jenkins.local (add to /etc/hosts: 127.0.0.1 jenkins.local)"
  echo "  - Jenkins Admin User: admin"

  # Try to get Jenkins password
  JENKINS_PASSWORD=$(kubectl exec -n jenkins $(kubectl get pods -n jenkins -l app.kubernetes.io/component=jenkins-controller -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) -- cat /run/secrets/additional/chart-admin-password 2>/dev/null || echo "admin")
  echo "  - Jenkins Admin Password: ${JENKINS_PASSWORD}"

  echo -e "\nApps Cluster:"
  echo "  - API Server: https://127.0.0.1:6444"
  echo "  - Flask App: http://localhost:30001"
  echo "  - Flask App Ingress: http://flask-app.local (add to /etc/hosts: 127.0.0.1 flask-app.local)"
  echo "  - Flask App Health: http://localhost:30001/health"

  echo -e "\nIngress Controllers:"
  echo "  - Dev Cluster Ingress: http://localhost:30081"
  echo "  - Apps Cluster Ingress: http://localhost:30080"

  echo -e "\nTo add host entries to your /etc/hosts file:"
  echo "  echo '127.0.0.1 jenkins.local flask-app.local' | sudo tee -a /etc/hosts"

  echo -e "\nTo switch between clusters:"
  echo "  - Dev Cluster: kubectl config use-context kind-dev-cluster"
  echo "  - Apps Cluster: kubectl config use-context kind-apps-cluster"

  echo -e "\nTo check the status of services:"
  echo "  - Jenkins: kubectl get pods -n jenkins"
  echo "  - Flask App: kubectl get pods -n flask"

  echo -e "\nTo view logs:"
  echo "  - Jenkins: kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller"
  echo "  - Flask App: kubectl logs -n flask -l app=flask-app"

  echo -e "\nTo tear down the environment, run: make down"
}

# Main function
main() {
  print_section "K8s Platform Monorepo Setup"

  # Check prerequisites
  check_prerequisites

  # Set up environment
  setup_environment

  # Deploy Jenkins to dev cluster
  deploy_jenkins

  # Deploy Flask app to apps cluster
  deploy_applications

  # Print access information
  print_access_info

  print_section "Setup Complete"
  print_success "The K8s Platform Monorepo is now up and running!"
  print_success "Jenkins and Flask app should now be accessible at the URLs listed above."
  print_warning "If you encounter any issues, check the troubleshooting information above."
}

# Run the main function
main
