#!/bin/sh

: "${HOST_UID:=1000}"
: "${HOST_GID:=1000}"

getent group wordpress || addgroup -g "${HOST_GID}" wordpress
getent passwd wordpress || adduser -D -h /var/empty -s /sbin/nologin -u "${HOST_UID}" -G wordpress wordpress

rsync -a /wp/ /shared/
chown -R wordpress /shared
exec sleep infinity
