FROM ghcr.io/automattic/vip-container-images/php-fpm:8.0

RUN apk add --no-cache git
COPY entrypoint.sh setup.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
