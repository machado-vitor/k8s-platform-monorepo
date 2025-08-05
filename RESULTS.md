# Kubernetes Platform Monorepo - Solution

This document summarizes the solution implemented to fix the issue where "flaskapp and jenkins are not running" in the Kubernetes Platform Monorepo.

## Issue Diagnosis

After examining the repository, the following issues were identified:

1. **Flask Application Issues**
   - No deployment steps in the Makefile for the Flask app
   - Missing ingress controller in the apps cluster
   - Port configuration mismatches between the cluster and service

2. **Jenkins Issues**
   - Port configuration mismatches between the cluster and service
   - Missing ingress controller in the dev cluster
   - Incomplete deployment process in the Makefile

## Solution Implemented

The solution focused on creating a comprehensive `start.sh` script that automates the entire deployment process with proper error handling and verification steps.

### 1. Improved Flask App Deployment

- Added proper namespace creation and management
- Added building and loading of the Docker image directly from source
- Added health checks (liveness and readiness probes)
- Added ingress controller installation
- Added verification steps to ensure the app is running
- Provided better error handling and logging

### 2. Improved Jenkins Deployment

- Added dedicated deployment function for Jenkins
- Added ingress controller installation
- Created proper ConfigMap for Jenkins Configuration as Code
- Updated Helm chart values to match cluster configuration
- Added verification steps to ensure Jenkins is running
- Added password retrieval and display
- Provided better error handling and logging

### 3. Enhanced Start Script

- Added comprehensive prerequisite checks
- Improved environment setup process
- Added detailed access information
- Added troubleshooting guidance
- Ensured proper sequencing of deployment steps

## How to Run the Solution

1. **Prerequisites**
   - Docker
   - kubectl
   - kind (Kubernetes in Docker)
   - Helm
   - OpenTofu/Terraform (optional)

2. **Running the Script**
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

3. **Accessing the Services**
   - Jenkins: http://localhost:30082 or http://jenkins.local (after adding to /etc/hosts)
   - Flask App: http://localhost:30001 or http://flask-app.local (after adding to /etc/hosts)

## Verification Steps

After running the script, you can verify that both services are running:

1. **Verify Jenkins**
   ```bash
   kubectl config use-context kind-dev-cluster
   kubectl get pods -n jenkins
   ```
   Expected output: Jenkins pod should be in Running state

2. **Verify Flask App**
   ```bash
   kubectl config use-context kind-apps-cluster
   kubectl get pods -n flask
   ```
   Expected output: Flask app pod should be in Running state

3. **Test Jenkins Access**
   ```bash
   curl http://localhost:30082
   ```
   Expected output: Jenkins login page HTML

4. **Test Flask App Access**
   ```bash
   curl http://localhost:30001
   ```
   Expected output: JSON response from the Flask app

## Troubleshooting

If you encounter issues:

1. **Check Pod Status**
   ```bash
   kubectl get pods -n jenkins  # For Jenkins
   kubectl get pods -n flask    # For Flask app
   ```

2. **Check Pod Logs**
   ```bash
   kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller
   kubectl logs -n flask -l app=flask-app
   ```

3. **Check Service Status**
   ```bash
   kubectl get svc -n jenkins
   kubectl get svc -n flask
   ```

4. **Check Ingress Status**
   ```bash
   kubectl get ingress -n jenkins
   kubectl get ingress -n flask
   ```

5. **Check Ingress Controller**
   ```bash
   kubectl get pods -n ingress-nginx
   ```

## Conclusion

The updated `start.sh` script provides a comprehensive solution to the issue where "flaskapp and jenkins are not running". It ensures that both services are properly deployed, configured, and verified to be running. The script also provides detailed access information and troubleshooting guidance to help users diagnose and fix any issues that might arise.

By addressing port configuration mismatches, adding ingress controllers, and implementing proper verification steps, the solution ensures that both Jenkins and the Flask app are accessible and functioning correctly.
