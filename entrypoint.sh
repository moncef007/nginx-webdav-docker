#!/bin/sh

chown -R nginx:nginx /var/www/webdav
chmod -R 755 /var/www/webdav

chown -R nginx:nginx /tmp/nginx-client-body
chmod -R 755 /tmp/nginx-client-body

exec nginx -g 'daemon off;'
