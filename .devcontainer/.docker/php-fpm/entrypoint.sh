#!/bin/sh

set -x

if [ -n "${HOST_UID}" ] && [ -n "${HOST_GID}" ]; then
    echo "Changing UID and GID to ${HOST_UID}:${HOST_GID}"
    usermod -u "${HOST_UID}" www-data
    groupmod -g "${HOST_GID}" www-data
fi

chown www-data:www-data /wp/wp-content/mu-plugins /wp/config /wp/log /wp/wp-content/uploads /wp

# if [ -z "${MULTISITE}" ]; then
#     su-exec www-data:www-data /bin/sh /dev-tools/setup.sh database root "http://test.vipdev.lndo.site/" "Test"
# else
#     su-exec www-data:www-data /bin/sh /dev-tools/setup.sh database root "http://test.vipdev.lndo.site/" "Test" test.vipdev.lndo.site
# fi

exec /usr/local/bin/docker-php-entrypoint /usr/local/bin/run.sh
