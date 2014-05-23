#!/bin/sh


if [ -z "$1" ] || [ -z "$2" ]; then
        echo "usage: $0 daggre_auth_token daggre_hosts"
        exit 1
fi

cat <<EOF
# Specify host or hosts that run the daggre datastore/aggregator
daggre_auth_token=$1
daggre_hosts=$2:999

# Disk usage reporter specifics
agents_diskusage_customerdir=/storage/content/*/%account/%domain

# Web log traffic reporter specifics
alias_map_path=/storage/configuration/maps/vhost.map
user_map_path=/storage/configuration/maps/users.map
folder_user_parse_regexp = [/_\\\\\\\\]content[/\\\\\\\\]\d\d[/\\\\\\\\](\d+)/
iis_config = /storage/configuration_iis/applicationHost.config
EOF
