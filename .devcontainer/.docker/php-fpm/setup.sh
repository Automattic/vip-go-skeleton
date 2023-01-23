#!/bin/sh

DOMAIN="localhost.localdomain"

if [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}" ] && [ -n "${CODESPACE_NAME}" ]; then
    DOMAIN="${CODESPACE_NAME}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}-8080"
fi

/dev-tools/setup.sh database root "http://${DOMAIN}/" "Test"
