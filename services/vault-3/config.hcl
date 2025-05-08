telemetry {
  prometheus_retention_time = "12h"
  disable_hostname = true
}

storage "raft" {
  path = "/vault/data"
  node_id = "vault-3"

  retry_join {
    leader_api_addr = "http://vault-1:8200"
  }
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = "true"
}

seal "transit" {
  address     = "http://vault-transit-1:8200"
  key_name    = "autounseal"
  mount_path  = "transit/"
  tls_skip_verify = "true"
}

api_addr = "http://vault-3:8200"
cluster_addr = "http://vault-3:8201"
cluster_name = "vault-cluster"
ui = true
