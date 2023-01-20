FROM ghcr.io/automattic/vip-container-images/wordpress:6.1

RUN apk --no-cache add shadow
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
