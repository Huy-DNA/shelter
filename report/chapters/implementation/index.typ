= Implementation <implementation>

== Vault

The implementation organizes each Vault instance in its own directory:

```
services/
├── vault-1/
│   ├── .env             = Environment variables (credentials)
│   ├── .env.example     = Template for environment variables
│   ├── config.hcl       = Vault server configuration
│   ├── Dockerfile       = Container build instructions
│   ├── entrypoint.sh    = Container startup script
│   └── init.sh          = Initialization script (first node only)
├── vault-2/
│   ├── .env
│   ├── .env.example
│   ├── config.hcl
│   ├── Dockerfile
│   └── entrypoint.sh
├── vault-3/
│   ├── .env
│   ├── .env.example
│   ├── config.hcl
│   ├── Dockerfile
│   └── entrypoint.sh
├── vault-transit-1/
│   ├── .env
│   ├── .env.example
│   ├── config.hcl
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── init.sh
└── docker-compose.yml   = Service orchestration
```

*`vault-transit-1/config.hcl`* defines the transit server configuration:
- Uses file storage backend
- Configures API and cluster addresses

*`vault-{1,2,3}/config.hcl`* defines each cluster node's configuration:
- Uses Raft storage backend
- Specifies cluster addresses
- Configures the transit auto-unseal

=== Vault auto-unseal - Vault transit engine

For Vault auto-unseal, we use the simplest approach that Vault supports: the Vault Transit Engine. This implementation follows a "transit as a service" pattern, where one dedicated Vault instance (`vault-transit-1`) provides encryption services used to unseal the other Vault instances in the cluster.

==== Transit engine architecture

The implementation consists of:

1. *Transit Server*: A dedicated Vault instance (`vault-transit-1`) that runs the Transit secrets engine
2. *Vault Cluster*: Three Vault nodes (`vault-1`, `vault-2`, `vault-3`) configured to use the Transit engine for auto-unsealing

This approach provides several advantages:
- Eliminates the need for manual unseal operations
- Avoids dependency on external cloud KMS services
- Maintains security by separating the transit encryption from the main Vault cluster
- Simplifies the deployment pipeline

==== Transit server setup

The transit server is initialized first with a single unseal key for simplicity. It:
1. Enables the Transit secrets engine
2. Creates a dedicated `autounseal` encryption key
3. Defines a policy with limited permissions for the Vault cluster nodes to use
4. Generates a token bound to this policy
5. Stores this token in a KV store for secure retrieval by cluster nodes

The initialization script creates two important policies:
- `autounseal`: Limited to encrypt/decrypt operations using the transit key
- `unseal-key`: Limited to reading the transit token from the KV store

=== Transit token authentication flow

In our Vault deployment, the auto-unseal mechanism relies on a secure token exchange between the transit server and the Vault cluster nodes. Here's how this process works:

==== Transit token generation and storage

The transit Vault server (`vault-transit-1`) generates a specialized transit token during initialization:

1. First, the transit server enables the transit secrets engine for encryption operations
2. It creates a dedicated encryption key called "autounseal"
3. It defines a restricted policy called "autounseal" that only allows encrypt/decrypt operations
4. It generates a token bound to this policy using `vault token create -policy=autounseal -period=24h`
5. It stores this token in a KV store at the path `kv/auto-unseal/transit-token`

This transit token is what the Vault cluster nodes need to perform auto-unseal operations. However, the token shouldn't be directly accessible without authentication.

==== Secure token access control

To control access to the transit token, the transit server:

1. Creates a policy called "unseal-key" with very limited permissions:
  ```hcl
  path "kv/auto-unseal/transit-token" {
    capabilities = ["read"]
  }
  ```
  This policy only permits reading the transit token and nothing else.

2. Sets up userpass authentication:
  ```bash
  vault auth enable userpass
  vault write auth/userpass/users/internal-server
    password=$UNSEAL_PASSWORD
    policies=unseal-key
  ```
  This creates a service account that can only access the transit token.

The password is stored as an environment variable in the `.env` file mounted to each Vault container, keeping it secure and configurable.

==== Token retrieval process

When a Vault cluster node starts up, it follows this authentication flow to retrieve the transit token:

1. Authenticate to the transit server using the userpass credentials:
  ```bash
  VAULT_TOKEN=$(curl -s
      --request POST
      --data "{\"password\": \"$UNSEAL_PASSWORD\"}"
      http://vault-transit-1:8200/v1/auth/userpass/login/internal-server | jq -r '.auth.client_token')
  ```

2. Validate the authentication succeeded:
  ```bash
  if [ "$VAULT_TOKEN" == "null" ] || [ -z "$VAULT_TOKEN" ]; then
      echo "Authentication failed"
      exit 1
  fi
  ```

3. Use the authenticated token to retrieve the transit token:
  ```bash
  TRANSIT_TOKEN=$(curl -s
      --header "X-Vault-Token: $VAULT_TOKEN"
      http://vault-transit-1:8200/v1/kv/auto-unseal/transit-token | jq -r '.data.token')
  ```

4. Validate the transit token was successfully retrieved:
  ```bash
  if [ "$TRANSIT_TOKEN" == "null" ] || [ -z "$TRANSIT_TOKEN" ]; then
      echo "Failed to retrieve transit token"
      exit 1
  fi
  ```

5. Set the transit token as the environment variable for Vault:
  ```bash
  export VAULT_TOKEN=$TRANSIT_TOKEN
  ```

This multi-step authentication process ensures that only authorized Vault nodes can access the transit token needed for auto-unsealing operations. The temporary authentication token from userpass is only used to retrieve the actual transit token, which is then used for the auto-unseal process.

This security architecture creates a chain of trust where the transit server manages access to the encryption key, while still allowing automated unsealing without human intervention.

=== Vault cluster

Each Vault service in the cluster uses the Raft storage engine for data persistence and replication. Raft provides:
- Built-in high availability without external dependencies
- Strong consistency across the cluster
- Automatic leader election and failover
- Simple setup compared to external storage options

==== Cluster architecture

The Vault cluster follows a leader-follower topology:
- `vault-1` initializes as the first node and becomes the leader
- `vault-2` and `vault-3` join the cluster as followers
- All nodes can serve read requests
- Only the leader processes write operations

==== Auto-unseal process

The auto-unseal flow works as follows:

1. Each Vault node starts up and authenticates to the transit server
2. The node retrieves the transit token needed for auto-unseal operations
3. The node configures its seal type to use the transit server
4. When sealed, the node sends its encryption key to the transit server for decryption
5. The transit server decrypts and returns the key, allowing the node to unseal

==== Node initialization

Vault-1 has special handling as the first node:
1. Waits for the transit server to be available
2. Retrieves the transit token
3. Initializes itself if not already initialized
4. Becomes the leader of the Raft cluster

Vault-2 and Vault-3 follow a similar but simpler process:
1. Wait for vault-1 to be available
2. Retrieve the transit token
3. Join the Raft cluster using the `raft join` command
4. Start serving requests once joined

==== Startup sequence

The deployment follows a carefully orchestrated startup sequence:

1. `vault-transit-1` initializes first and becomes available for auto-unseal operations
2. `vault-1` waits for the transit server, then initializes as the first node in the cluster
3. `vault-2` and `vault-3` wait for `vault-1` to be ready, then join the cluster

This sequence ensures that dependencies are satisfied before each service attempts to start, preventing race conditions and initialization failures.

== Reverse Proxy / Load Balancer (NGINX)

#include "nginx.typ"