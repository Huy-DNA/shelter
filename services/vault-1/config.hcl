storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

seal "transit" {
  address     = "http://vault-transit:8200"
  key_name    = "autounseal"
  mount_path  = "transit/"
  token       = "${VAULT_TRANSIT_TOKEN}"
}

api_addr = "http://vault-1:8200"
cluster_addr = "http://vault-1:8201"
ui = true
