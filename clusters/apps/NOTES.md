# Applications Cluster

This cluster is intended for deploying and testing applications. It is separate from the development cluster to provide isolation between platform services and application workloads.

## Cluster Details

- **Name**: apps-cluster
- **Nodes**: 1 control-plane, 3 workers
- **Port Mappings**:
  - 8081 -> HTTP (mapped from 80)
  - 8444 -> HTTPS (mapped from 443)
  - 5001 -> Flask Application (mapped from 5000)

## Applications Deployed

The following applications are deployed on this cluster:

1. **Flask App** - Sample Python Flask application
   - URL: http://localhost:5001
   - Source: `/apps/flask`

## Usage

### Starting the Cluster

```bash
make apps-cluster
```

### Accessing the Cluster

```bash
kubectl config use-context kind-apps-cluster
kubectl get nodes
kubectl get pods -A
```

### Deploying Applications

Applications can be deployed using Helm:

```bash
cd apps/flask
helm upgrade --install flask-app ./charts/myapp --namespace flask --create-namespace
```

### Accessing Applications

The Flask application can be accessed at http://localhost:5001

### Stopping the Cluster

```bash
kind delete cluster --name apps-cluster
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 8081, 8444, and 5001 are not in use by other applications.
2. **Resource constraints**: The cluster requires at least 6GB of RAM and 3 CPU cores.
3. **Docker issues**: Ensure Docker is running and has sufficient resources allocated.

### Logs

To view logs for the cluster:

```bash
kind export logs --name apps-cluster ./apps-cluster-logs
```

### Application Logs

To view logs for the Flask application:

```bash
kubectl logs -n flask -l app=flask-app
```
