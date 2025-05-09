FROM linuxtips/prometheus_alpine:latest

USER root
COPY prometheus.yml /etc/prometheus/prometheus.yml.template
COPY .env /.env
COPY entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
RUN apk add curl jq gettext

RUN find /etc/prometheus/ -type f -name "*.yml" -exec dos2unix {} \;
RUN find / -type f -name "*.sh" -exec dos2unix {} \;

EXPOSE 9090

ENTRYPOINT [ "/entrypoint.sh" ]
