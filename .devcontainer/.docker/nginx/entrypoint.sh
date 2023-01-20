#!/bin/sh

if [ -n "${HOST_UID}" ] && [ -n "${HOST_GID}" ]; then
    if [ "${HOST_UID}" != "0" ]; then
        echo "Changing UID and GID to ${HOST_UID}:${HOST_GID}"
        usermod -u "${HOST_UID}" -d /wp -s /bin/bash nginx
        groupmod -g "${HOST_GID}" nginx
    else
        usermod -d /wp -s /bin/bash nginx
    fi
fi

exec /docker-entrypoint.sh nginx -g "daemon off;"
