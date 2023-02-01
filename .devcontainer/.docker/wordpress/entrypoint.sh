#!/bin/sh

: "${HOST_UID:=1000}"
: "${HOST_GID:=1000}"

getent group wordpress || addgroup -g "${HOST_GID}" wordpress
getent passwd wordpress || adduser -D -h /var/empty -u "${HOST_UID}" -G wordpress wordpress

chown -R wordpress:wordpress /shared
rsync -a /wp/ /shared/
exec sleep infinity
