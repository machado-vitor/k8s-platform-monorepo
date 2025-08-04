// Jenkins Job DSL script to create initial jobs
// This script will be executed by the Job DSL plugin

// Create folders for organization
folder('infrastructure') {
    displayName('Infrastructure')
    description('Infrastructure jobs')
}

folder('applications') {
    displayName('Applications')
    description('Application jobs')
}

// Infrastructure jobs
pipelineJob('infrastructure/terraform-apply') {
    description('Apply Terraform/OpenTofu changes to infrastructure')

    parameters {
        choiceParam('ENVIRONMENT', ['dev', 'staging', 'prod'], 'Environment to deploy to')
        booleanParam('AUTO_APPROVE', false, 'Automatically approve Terraform plan')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('file:///var/jenkins_home/workspace/infra')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }

    triggers {
        scm('H/15 * * * *')
    }
}

pipelineJob('infrastructure/monitoring-deploy') {
    description('Deploy monitoring stack')

    parameters {
        choiceParam('ENVIRONMENT', ['dev', 'staging', 'prod'], 'Environment to deploy to')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('file:///var/jenkins_home/workspace/infra/modules/monitoring')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
}

// Application jobs
pipelineJob('applications/flask-app') {
    description('Build and deploy Flask application')

    parameters {
        stringParam('VERSION', '1.0.0', 'Application version')
        choiceParam('ENVIRONMENT', ['dev', 'staging', 'prod'], 'Environment to deploy to')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('file:///var/jenkins_home/workspace/apps/flask')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }

    triggers {
        scm('H/5 * * * *')
    }
}

// Utility jobs
pipelineJob('utilities/cluster-cleanup') {
    description('Clean up resources in the cluster')

    parameters {
        choiceParam('CLUSTER', ['dev-cluster', 'apps-cluster'], 'Cluster to clean up')
        booleanParam('DRY_RUN', true, 'Dry run (no actual deletion)')
    }

    definition {
        cps {
            script('''
                pipeline {
                    agent {
                        kubernetes {
                            label 'jenkins-agent'
                        }
                    }
                    stages {
                        stage('Cleanup') {
                            steps {
                                withKubeConfig([credentialsId: 'k8s-credentials', contextName: params.CLUSTER]) {
                                    sh """
                                        if [ "\${params.DRY_RUN}" = "true" ]; then
                                            echo "Dry run mode - would delete these resources:"
                                            kubectl get pods --all-namespaces | grep Evicted
                                            kubectl get pods --all-namespaces | grep Completed
                                        else
                                            echo "Deleting evicted pods..."
                                            kubectl get pods --all-namespaces | grep Evicted | awk '{print "kubectl delete pod -n " \$1 " " \$2}' | sh
                                            echo "Deleting completed pods..."
                                            kubectl get pods --all-namespaces | grep Completed | awk '{print "kubectl delete pod -n " \$1 " " \$2}' | sh
                                        fi
                                    """
                                }
                            }
                        }
                    }
                }
            '''.stripIndent())
        }
    }

    triggers {
        cron('0 0 * * *')  // Run daily at midnight
    }
}
