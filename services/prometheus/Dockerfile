FROM prom/prometheus:latest

USER root
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh

RUN find /etc/prometheus/ -type f -name "*.yml" -exec dos2unix {} \;
RUN find / -type f -name "*.sh" -exec dos2unix {} \;

USER 65534

EXPOSE 9090

ENTRYPOINT [ "/entrypoint.sh" ]
