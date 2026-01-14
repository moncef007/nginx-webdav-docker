#!/bin/sh

SSL_ENABLED="${SSL_ENABLED:-false}"
SSL_MODE="${SSL_MODE:-auto}"

echo "SSL_ENABLED=${SSL_ENABLED}"
echo "SSL_MODE=${SSL_MODE}"

if [ "${SSL_ENABLED}" = "true" ]; then
    echo "HTTPS mode enabled"

    if [ "${SSL_MODE}" = "auto" ]; then
        if [ ! -f /etc/nginx/ssl/server.crt ] || [ ! -f /etc/nginx/ssl/server.key ]; then
            echo "Auto-generating self-signed SSL certificate..."

            SSL_CN="${SSL_CN:-localhost}"
            SSL_ORG="${SSL_ORG:-WebDAV Server}"
            SSL_DAYS="${SSL_DAYS:-365}"

            openssl req -x509 -nodes -days "${SSL_DAYS}" -newkey rsa:2048 \
                -keyout /etc/nginx/ssl/server.key \
                -out /etc/nginx/ssl/server.crt \
                -subj "/C=FR/ST=Ile-de-France/L=Paris/O=${SSL_ORG}/CN=${SSL_CN}" \
                -addext "subjectAltName=DNS:${SSL_CN},DNS:localhost,IP:127.0.0.1"

            chmod 600 /etc/nginx/ssl/server.key
            chmod 644 /etc/nginx/ssl/server.crt
            echo "SSL certificate generated for CN=${SSL_CN}"
        else
            echo "Using existing SSL certificates (auto mode)"
        fi
    elif [ "${SSL_MODE}" = "custom" ]; then
        if [ ! -f /etc/nginx/ssl/server.crt ] || [ ! -f /etc/nginx/ssl/server.key ]; then
            echo "ERROR: SSL_MODE=custom but certificates not found!"
            echo "Please copy your certificates to data/ssl/:"
            echo "  - data/ssl/server.crt"
            echo "  - data/ssl/server.key"
            exit 1
        fi
        echo "Using custom SSL certificates"
    else
        echo "ERROR: Invalid SSL_MODE '${SSL_MODE}'. Use 'auto' or 'custom'."
        exit 1
    fi

    cp /etc/nginx/nginx-https.conf /etc/nginx/nginx.conf
else
    echo "HTTP mode enabled (no SSL)"
    cp /etc/nginx/nginx-http.conf /etc/nginx/nginx.conf
fi

chown -R nginx:nginx /var/www/webdav
chmod -R 755 /var/www/webdav

chown -R nginx:nginx /tmp/nginx-client-body
chmod -R 755 /tmp/nginx-client-body

exec nginx -g 'daemon off;'
