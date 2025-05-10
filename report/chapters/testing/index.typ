= Testing

Deployment on 2 nodes:

#figure(
  caption: "The services running on 2 nodes",
  image("../../static/2-node.jpg"),
) <two-node>

Accessing remote services on the other machine:

#figure(
  caption: "Remotely accessing Vault on the other machine",
  image("../../static/remote-vault.jpg"),
)

#figure(
  caption: "Remotely accessing Prometheus on the other machine",
  image("../../static/remote-prometheus.jpg"),
)

== One node dies

One node dies:

#figure(
  caption: "One node down",
  image("../../static/1-node-down.jpg"),
)

Accessing Vault and Prometheus still fine:

#figure(
  caption: "Accessing Vault",
  image("../../static/1-node-down-vault.jpg"),
)

#figure(
  caption: "Accessing Prometheus",
  image("../../static/1-node-down-prometheus.jpg"),
)

== Leader killed

The leader (`vault-1` killed):

#figure(
  caption: "Vault-1 killed",
  image("../../static/leader-killed.jpg"),
)

Accessing Vault still fine:

#figure(
  caption: "Accessing Vault",
  image("../../static/leader-killed-vault.jpg"),
)
