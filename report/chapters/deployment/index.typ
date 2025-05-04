= Deployment <deployment>
We use Docker Swarm @testdriven-vault-consul to deploy our Vault-based Architecture. The system consists of multiple Vault nodes (including one for transit auto-unseal), NGINX as a reverse proxy, and Prometheus and Grafana for monitoring. The deployment uses custom Vault images and automated configuration through a shell script.

== Architecture Overview

The deployment includes the following services:

- `vault-1`, `vault-2`, `vault-3`: A three-node Vault cluster forming a High Availability (HA) setup.
- `vault-transit-1`: A dedicated Vault instance running the Transit secrets engine for auto-unsealing other Vault nodes.
- `nginx`: Acts as a reverse proxy for routing traffic to Vault and monitoring endpoints.
- `prometheus`: Collects metrics from services for monitoring.
- `grafana`: Visualizes metrics collected by Prometheus.

All services are connected through a Docker Swarm overlay network named `vault-network`.

== Auto Unseal with Vault Transit Engine

To enable auto unseal, the primary Vault nodes (`vault-1`, `vault-2`, `vault-3`) are configured to use the Transit secrets engine hosted on `vault-transit-1`. This method avoids manual re-unsealing on restarts and improves automation and resilience.

== Docker Swarm Deployment

All services are deployed in Docker Swarm using a `docker-compose.yml` file. Key configurations include:

- Each Vault node runs in a single replica mode for strict control.
- Prometheus, Grafana, and NGINX run in replicated mode (3 replicas each) to support load balancing and high availability.
- Persistent volumes are defined for all Vault nodes and Grafana to ensure data durability.
- The Prometheus configuration is injected using Docker configs.

== Deployment Script

```
#!/bin/sh
set -e

echo "Cleaning up old Docker services, containers, volumes, images..."

docker service rm vault_vault-1 vault_vault-2 vault_vault-3 vault_vault-transit-1 vault_prometheus vault_grafana || echo "Services not created yet"

for IMAGE in vault-1 vault-2 vault-3 vault-transit-1; do
  docker rm $(docker ps -a --filter ancestor=$IMAGE --format="{{.ID}}") --force 2>/dev/null || echo "Containers for $IMAGE not found"
done

docker volume rm vault_vault-1-data vault_vault-2-data vault_vault-3-data vault_vault-transit-1-data grafana-data || echo "Volumes not created yet"

docker rmi vault-1 vault-2 vault-3 vault-transit-1 --force || echo "Images not created yet"

echo "Cleaning old Docker config for Prometheus (if exists)..."
docker config rm prometheus-config 2>/dev/null || echo "No existing prometheus-config to remove"

echo "Creating new Docker config for Prometheus..."
docker config create prometheus-config ./prometheus/prometheus.yml

echo "Initializing Docker Swarm (if not active)..."
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
  docker swarm init || echo "Swarm already initialized"
fi

echo "🔨 Building Vault service images..."
for SERVICE in vault-1 vault-2 vault-3 vault-transit-1; do
  echo "Building $SERVICE..."
  (cd $SERVICE && docker build -t $SERVICE .)
done

echo "Deploying full Vault stack with Prometheus and Grafana..."
docker stack deploy --compose-file=docker-compose.yml vault

echo "Vault stack deployment complete."

```
The deployment is managed by a shell script that performs the following tasks:

1. Cleans up old containers, volumes, and images related to Vault and monitoring stack.
2. Deletes and recreates the Prometheus Docker config.
3. Initializes Docker Swarm if it hasn't been already.
4. Builds custom Docker images for all Vault-related services.
5. Deploys the entire stack using `docker stack deploy`.

== Monitoring Stack

- *Prometheus*: Scrapes metrics from services. Configuration is provided via an external config file.
- *Grafana*: Provides dashboards for visualizing metrics. Persists data using a named volume (`grafana-data`).

== Networking and Security

- All services share an `overlay` network (`vault-network`) which is attachable, facilitating secure inter-service communication.
- Vault containers are granted `IPC_LOCK` capability for memory locking, improving security.


