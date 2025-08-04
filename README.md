# Kubernetes Platform Monorepo

This repository contains a complete Kubernetes platform setup including infrastructure configuration, application deployments, and CI/CD pipelines.

## Repository Structure

- `clusters/`: Local cluster configurations (kind) and Kubernetes documentation
- `jenkins/`: Jenkins installation and configuration
- `infra/`: Infrastructure as code using OpenTofu/Terraform
- `apps/`: Application source code, Dockerfiles, and Helm charts
- `lib/`: Jenkins Shared Library for reusable CI/CD steps

## Getting Started

### Prerequisites

- Docker
- kubectl
- kind (Kubernetes in Docker)
- Helm
- OpenTofu/Terraform

### Setup

1. Clone this repository
2. Navigate to the project root directory: `cd k8s-platform-monorepo`
3. Run `make up` to start both the development and applications clusters
   - Alternatively, run `make dev-cluster` to start only the development cluster
   - Alternatively, run `make apps-cluster` to start only the applications cluster
   - **Note**: All `make` commands must be run from the project root directory
4. Alternatively, you can use the provided setup script: `./start.sh` which will check prerequisites and set up the entire environment
5. Access the applications and services as described in the cluster documentation

## Development Workflow

1. Make changes to applications or infrastructure
2. Test locally using `make up`
3. Submit a pull request
4. CI/CD pipelines will validate and deploy changes

## Cleanup

Run `make down` to tear down the local development environment.
