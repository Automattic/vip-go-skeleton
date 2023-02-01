FROM ghcr.io/automattic/vip-container-images/php-fpm:8.0

RUN apk add --no-cache git
COPY entrypoint.sh setup.sh /usr/local/bin/

ENV WP_CLI_ALLOW_ROOT 1
ENV COMPOSER_ALLOW_SUPERUSER 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
