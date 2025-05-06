= Design <design>

Our high-level design is shown in @system-design. As mentioned, we use:
- ZeroTier as a VPN layer for all of the machines providing the service.
- Vault transit engine as the autounseal mechanism.
- Prometheus for telemetry collection.
- Grafana for telemetry visualization.
- NGINX for load balancer.

#figure(caption: "Design", image("../../static/design.jpg")) <system-design>
