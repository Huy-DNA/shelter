FROM hashicorp/vault

EXPOSE 8200
EXPOSE 8201

COPY config.hcl /vault/config/vault-config.hcl
COPY .env /vault/config/.env
RUN chmod 700 /vault/config/.env

COPY entrypoint.sh /vault/entrypoint.sh
RUN chmod +x /vault/entrypoint.sh

RUN apk add dos2unix
RUN find /vault -type f -name "*.sh" -exec dos2unix {} \;

ENV VAULT_ADDR=http://vault-1:8200
ENV VAULT_API_ADDR=http://vault-3:8200

ENTRYPOINT ["/vault/entrypoint.sh"]
