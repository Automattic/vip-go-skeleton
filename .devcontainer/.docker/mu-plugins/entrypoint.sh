#!/bin/sh

: "${HOST_UID:=1000}"
: "${HOST_GID:=1000}"

if [ "${HOST_UID}" != "0" ]; then
    getent group www-data || addgroup -g "${HOST_GID}" www-data
    getent passwd www-data || adduser -D -h /var/empty -s /sbin/nologin -u "${HOST_UID}" -G www-data www-data
    chown -R www-data /shared
fi

exec /bin/sleep infinity
