# Development Cluster

This cluster is intended for platform development and hosting core services like Jenkins, monitoring tools, and other infrastructure components.

## Cluster Details

- **Name**: dev-cluster
- **Nodes**: 1 control-plane, 2 workers
- **Port Mappings**:
  - 8083 -> HTTP (mapped from 80)
  - 8443 -> HTTPS (mapped from 443)
  - 8080 -> Jenkins UI (mapped from 8080)

## Services Deployed

The following services are deployed on this cluster:

1. **Jenkins** - CI/CD server
   - URL: http://localhost:8080
   - Credentials: See Jenkins documentation in `/jenkins/README.md`

2. **Monitoring Stack** - Prometheus, Grafana, and Alertmanager
   - Grafana URL: http://localhost:3000
   - Default credentials: admin/admin

## Usage

### Starting the Cluster

```bash
make dev-cluster
```

### Accessing the Cluster

```bash
kubectl config use-context kind-dev-cluster
kubectl get nodes
```

### Stopping the Cluster

```bash
kind delete cluster --name dev-cluster
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 8083, 8443, and 8082 are not in use by other applications.
2. **Resource constraints**: The cluster requires at least 4GB of RAM and 2 CPU cores.
3. **Docker issues**: Ensure Docker is running and has sufficient resources allocated.

### Logs

To view logs for the cluster:

```bash
kind export logs --name dev-cluster ./dev-cluster-logs
```
