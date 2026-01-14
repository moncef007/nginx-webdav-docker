FROM nginx:1.28.0-alpine

RUN apk add --no-cache apache2-utils openssl

RUN mkdir -p /var/www/webdav && \
    chmod -R 777 /var/www/webdav

RUN mkdir -p /tmp/nginx-client-body && \
    chmod -R 777 /tmp/nginx-client-body

RUN mkdir -p /etc/nginx/ssl && \
    chmod 700 /etc/nginx/ssl

COPY entrypoint.sh /entrypoint.sh
COPY conf/nginx.conf /etc/nginx/nginx-http.conf
COPY conf/nginx-https.conf /etc/nginx/nginx-https.conf
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
