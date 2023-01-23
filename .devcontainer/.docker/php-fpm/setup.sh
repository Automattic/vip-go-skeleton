#!/bin/sh

DOMAIN="localhost.localdomain"

if [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}" ] && [ -n "${CODESPACE_NAME}" ]; then
    DOMAIN="${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
fi

/dev-tools/setup.sh database root "http://${DOMAIN}/" "Test"
