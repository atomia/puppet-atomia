#!/bin/sh

if [ -z "$7" ]; then
        echo "usage: $0 cron_global_auth_token min_part max_part mail_host mail_port mail_ssl mail_from mail_user mail_pass"
        exit 1
fi

cat <<EOF
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DBNAME=cronagent
CRON_LISTEN_PORT=10101
CRON_GLOBAL_AUTH_TOKEN=$1
MIN_PART=$2
MAX_PART=$3
INTERVAL=60
MAIL_HOST=$4
MAIL_PORT=$5
MAIL_USER=$8
MAIL_PASS=$9
MAIL_SSL=$6
MAIL_FROM=$7
EOF
