#!/bin/sh

cat <<EOF
AGENT_USERNAME="$1"
AGENT_PASSWORD="$2"
#AGENT_PORT="3000"
#AGENT_SQLITE_PATH="/usr/lib/atomia-pa-haproxy/atomia-pa-haproxy.sqlite"
#HAPROXY_CONFIG_FILE="/etc/haproxy/haproxy.cfg"
#HAPROXY_STATUS_PORT="10001"
#HAPROXY_STATUS_USER="status"
#HAPROXY_STATUS_PASS="status"
EOF
