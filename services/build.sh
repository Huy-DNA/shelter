#!/bin/sh
set -e

echo "🔄 Initializing Docker Swarm (if not active)..."
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
  docker swarm init || echo "Swarm already initialized"
fi

echo "🔨 Building Vault service images..."
for SERVICE in vault-1 vault-2 vault-3 vault-transit-1 load-balancer prometheus; do
  echo "➡️ Building $SERVICE..."
  (cd $SERVICE && docker build -t $SERVICE .)
done

echo "🚀 Deploying full Vault stack with Prometheus and Grafana..."
docker stack deploy --compose-file=docker-compose.yml vault

echo "✅ Vault stack deployment complete."
