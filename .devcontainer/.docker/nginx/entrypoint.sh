#!/bin/sh

if [ -n "${HOST_UID}" ] && [ -n "${HOST_GID}" ]; then
    echo "Changing UID and GID to ${HOST_UID}:${HOST_GID}"
    usermod -u "${HOST_UID}" nginx
    groupmod -g "${HOST_GID}" nginx
fi

exec /docker-entrypoint.sh nginx -g "daemon off;"
