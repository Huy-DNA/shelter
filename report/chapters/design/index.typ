= Prometheus Monitoring Design <prometheus-design>

== 1. Monitoring Objectives
The goal of the monitoring system is to ensure the high availability and operational health of the Vault deployment. Prometheus collects metrics from all Vault nodes and related services, allowing operators to:
- Detect unseal or cluster issues
- Monitor request rates and token creation
- Track system resource usage (CPU, RAM, Disk)
- Provide data visualization and alerts

== 2. Prometheus Deployment
Prometheus is deployed as a Docker Swarm service with 3 replicas. It connects to the internal overlay network `vault-network`. Configuration is injected via Docker config (`prometheus-config`). Data is stored using a persistent volume.
#figure(image("../../static/prometheus-architecture.png"), caption: [Prometheus and Vault Monitoring Architecture])
== 3. Metrics Collection Configuration
Each Vault node exposes metrics via `/v1/sys/metrics?format=prometheus`. Prometheus is configured to scrape them as follows:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'vault-1'
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    static_configs:
      - targets: ['vault-1:8200']

  - job_name: 'vault-2'
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    static_configs:
      - targets: ['vault-2:8200']

  - job_name: 'vault-3'
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    static_configs:
      - targets: ['vault-3:8200']

  - job_name: 'vault-transit-1'
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    static_configs:
      - targets: ['vault-transit-1:8200']
```

== 4. Grafana Integration
Grafana is configured to use Prometheus as a data source. Dashboards include:
- Vault health and leader election
- Token usage and secret engine performance
- System metrics from node_exporter

== 5. Security Considerations
- Prometheus endpoint should not be exposed publicly.
- Network access is restricted to internal Docker Swarm network.
- Secure Vault metric endpoints with TLS or access control if necessary.
