= Introduction <introduction>

In this assignment, we deploy HashiCorp Vault service (https://www.vaultproject.io/) to a virtual cluster on top of VPN with a focus on high availability.

== About HashiCorp Vault

In today's digital landscape, securing sensitive information such as API keys, passwords, certificates, and other secrets is paramount for organizations of all sizes. Traditional approaches to secrets management often fall short, resulting in hard-coded credentials, shared password files, or manual distribution methods that create significant security vulnerabilities and operational inefficiencies. More modern approaches defer these responsibilities to a specialized secret management service. HashiCorp Vault plays the role of this specialized service. HashiCorp Vault provides a centralized service for securing, storing, and tightly controlling access to secrets across distributed applications and infrastructure, addressing the critical need for robust secrets management in modern technology stacks.

== About the technology stack

Our implementation leverages:
- Docker Swarm: container orchestration and service management, ensuring seamless scaling and failover capabilities.
- ZeroTier: the foundation for our virtual private network, creating a secure communication layer between distributed nodes.
- NGINX: A reverse proxy and load balancer, optimizing request distribution while enhancing security.
- Prometheus & Grafana: Comprehensive monitoring and visibility by tracking system health, performance metrics, and security events.

By combining these technologies, we demonstrate a resilient, secure, and highly available HashiCorp Vault service, through which a general automatic high-availability deployment framework is presented.
