# Changes Made to Fix Jenkins Installation

## Issue
The issue was that Jenkins was not installed in the Kubernetes cluster. The error message was simply "jenkins is not installed".

## Root Causes
After investigating, two main issues were identified:

1. **Outdated Helm Chart Configuration**: The Jenkins Helm chart values file was using an outdated parameter structure for the agent configuration. Specifically, it was using `agent.tag` instead of `agent.image.tag`, which is the new parameter name in the latest Jenkins Helm chart.

2. **JCasC Configuration Issue**: The Jenkins Configuration as Code (JCasC) setup was trying to include a configuration file using `${file:/var/jenkins_home/casc_configs/jenkins.yaml}`, but this was causing errors because the file wasn't accessible or the syntax was incorrect.

## Changes Made

### 1. Updated Agent Configuration
Modified the agent configuration in `jenkins/charts/values.yaml` to use the new parameter structure:

```yaml
# Agent configurations
agent:
  enabled: true
  image:
    repository: "jenkins/inbound-agent"
    tag: "latest-jdk11"
```

### 2. Fixed JCasC Configuration
Instead of trying to include the JCasC configuration from a file, we directly included the content of `jenkins/jcasc/jenkins.yaml` in the `jenkins/charts/values.yaml` file:

```yaml
# JCasC configuration
JCasC:
  enabled: true
  defaultConfig: false
  configScripts:
    jenkins-config: |
      jenkins:
        systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin"
        # ... rest of the configuration ...
```

### 3. Removed Unnecessary Volumes
Since we're no longer using a ConfigMap for the JCasC configuration, we removed the `volumes` and `volumeMounts` sections from the values file.

## How to Use Jenkins

Jenkins is now installed and running in the Kubernetes cluster. You can access it at:

- URL: http://localhost:31534 (NodePort service)
- Username: admin
- Password: admin (default, should be changed in production)

You can also access Jenkins through the Ingress if it's set up:

- URL: http://jenkins.local (add to /etc/hosts: 127.0.0.1 jenkins.local)

## Troubleshooting

If you encounter issues with Jenkins:

1. Check the pod status: `kubectl get pods -n jenkins`
2. Check the logs: `kubectl logs -n jenkins jenkins-0 -c jenkins`
3. Restart Jenkins if needed: `kubectl rollout restart statefulset jenkins -n jenkins`

## Note

There might still be some issues with Jenkins plugins or their dependencies based on the logs. If you encounter problems with specific plugins, you may need to update the plugin list in the values file.
