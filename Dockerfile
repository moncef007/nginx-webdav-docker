FROM nginx:1.28.0-alpine

RUN apk add --no-cache apache2-utils

RUN mkdir -p /var/www/webdav && \
    chmod -R 777 /var/www/webdav

RUN mkdir -p /tmp/nginx-client-body && \
    chmod -R 777 /tmp/nginx-client-body

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
