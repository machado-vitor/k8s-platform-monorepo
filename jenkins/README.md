# Jenkins Configuration

This directory contains the configuration for Jenkins CI/CD server deployed on the development cluster.

## Overview

Jenkins is deployed using Helm and configured using the Jenkins Configuration as Code (JCasC) plugin. The configuration includes:

- Jenkins controller and agent setup
- Security configuration
- Plugin installation
- Job definitions
- Credentials management
- Kubernetes integration

## Directory Structure

- `charts/`: Contains Helm values for Jenkins installation
- `jcasc/`: Contains Jenkins Configuration as Code files
- `seed-jobs.groovy`: Job DSL script to create initial Jenkins jobs

## Installation

Jenkins is automatically installed on the development cluster when running:

```bash
make dev-cluster
```

This will:
1. Create the development cluster using kind
2. Install Jenkins using Helm with the values from `charts/values.yaml`
3. Configure Jenkins using the JCasC file from `jcasc/jenkins.yaml`
4. Create initial jobs using the Job DSL script in `seed-jobs.groovy`

## Accessing Jenkins

Once deployed, Jenkins can be accessed at:

- URL: http://localhost:8080
- Username: admin
- Password: admin (default, should be changed in production)

## Jobs

The following jobs are created by default:

### Infrastructure Jobs

- **terraform-apply**: Applies Terraform/OpenTofu changes to infrastructure
- **monitoring-deploy**: Deploys the monitoring stack

### Application Jobs

- **flask-app**: Builds and deploys the Flask application

### Utility Jobs

- **cluster-cleanup**: Cleans up resources in the cluster

## Customization

### Adding Plugins

To add additional plugins, modify the `installPlugins` section in `charts/values.yaml`.

### Modifying Configuration

To modify the Jenkins configuration, edit the `jcasc/jenkins.yaml` file.

### Adding Jobs

To add new jobs, modify the `seed-jobs.groovy` file.

## Troubleshooting

### Common Issues

1. **Jenkins not starting**: Check the pod logs with `kubectl logs -n jenkins jenkins-0`
2. **Configuration not applied**: Verify the ConfigMap was created and mounted correctly
3. **Jobs not created**: Check the Jenkins logs for Job DSL errors

### Restarting Jenkins

To restart Jenkins:

```bash
kubectl rollout restart statefulset jenkins -n jenkins
```

## References

- [Jenkins Helm Chart Documentation](https://github.com/jenkinsci/helm-charts)
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Job DSL Plugin](https://github.com/jenkinsci/job-dsl-plugin)
