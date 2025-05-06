NGINX's configuration in this project is tailored to support the Vault cluster @nginx-load-balancing. Here’s how it’s set up:

=== Upstream Block
The `upstream` directive defines the group of backend Vault servers:
```
upstream vault_backend {
    server vault-1:8200;
    server vault-2:8200;
    server vault-3:8200;
    keepalive 64;
}
```
- *Servers*: Lists three Vault nodes (`vault-1`, `vault-2`, `vault-3`) on port 8200.
- *Keepalive*: Maintains 64 persistent connections per server, reducing connection overhead.

=== Location Block
The `location` block handles requests to the root path (`/`):
```
location / {
    proxy_pass http://vault_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_intercept_errors on;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_connect_timeout 30s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
```
- *`proxy_pass`*: Forwards requests to the `vault_backend` group, enabling load balancing.
- *Headers*: Passes client details (e.g., IP, protocol) to Vault nodes for logging and security.
- *Timeouts*: Sets limits for connection (30s), sending (60s), and reading (60s) operations.
- *HTTP/1.1*: Supports persistent connections and WebSocket upgrades.

=== Health and Debug Endpoints
Additional endpoints provide monitoring and troubleshooting:
```
location /health {
    return 200 "NGINX is healthy\n";
}

location /debug {
    return 200 "Debug information: $time_local\n";
}
```
- *`/health`*: Returns a status message for monitoring tools.
- *`/debug`*: Provides the current server time for diagnostics.

=== Docker Compose Setup
NGINX is deployed via Docker Compose:
```yaml
nginx:
  image: nginx
  hostname: nginx
  ports:
    - "80:80"
  networks:
    - vault-network
  deploy:
    mode: replicated
    replicas: 3
```
- *Replicas*: Runs three NGINX instances for redundancy.
- *Ports*: Maps port 80 on the host to NGINX.
- *Network*: Connects to `vault-network` for Vault communication.

=== Role in the System

NGINX integrates seamlessly with the Vault cluster, enhancing its functionality:

==== Request Flow
1. A client sends a request to NGINX (e.g., `http://nginx:80/`).
2. NGINX selects a Vault node from `vault_backend` and forwards the request.
3. The Vault node processes it and responds to NGINX.
4. NGINX relays the response to the client.

==== Load Balancing
- Distributes requests evenly across `vault-1`, `vault-2`, and `vault-3`.
- Ensures optimal resource use and prevents bottlenecks.

==== High Availability
- Three NGINX replicas provide failover; if one fails, traffic shifts to others.
- NGINX skips unavailable Vault nodes, maintaining service continuity.

==== Monitoring
- The `/health` endpoint allows external tools to verify NGINX’s status.
- The `/debug` endpoint aids in troubleshooting.
