FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

RUN echo "http://nl.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories && \
    echo "http://nl.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

RUN apk update && \
    apk add --no-cache curl jq dos2unix

RUN find /etc/nginx -type f -name "*.conf" -exec dos2unix {} \;

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
