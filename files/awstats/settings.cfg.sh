#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "usage: $0 user pass ssl|nossl"
        exit 1
fi

if [ x"$3" = x"ssl" ]; then
        ssl="True"
else
        ssl="False"
fi

cat <<EOF
[settings]
AWSTATS_CONFIG_DIR          = /etc/awstats/
REPORTS_DEDICATED_SITE_PATH = /storage/content/awstats-sites
SERVICE_PORT                = 8888
SERVICE_AUTH                = True
SERVICE_AUTH_USER           = $1
SERVICE_AUTH_PW             = $2
SERVE_HTTPS                 = $ssl
CERTIFICATE_FILE            = /usr/local/awstats-agent/wildcard.crt
PRIVATE_KEY_FILE            = /usr/local/awstats-agent/wildcard.key

