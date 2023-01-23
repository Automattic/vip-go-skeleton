FROM ghcr.io/automattic/vip-container-images/php-fpm:8.0

RUN apk add --no-cache git
RUN wget -q https://getcomposer.org/installer -O - | php -- --install-dir=/usr/bin/ --filename=composer
COPY entrypoint.sh setup.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
