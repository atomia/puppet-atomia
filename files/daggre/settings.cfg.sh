#!/bin/sh

if [ -z "$1" ]; then
        echo "usage: $0 daggre_global_auth_token"
        exit 1
fi

cat <<EOF
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DBNAME=daggre
MONGO_COLLECTION_NAME=daggre
DAGGRE_IN_MEM_AGGREGATION_TIME=12000
DAGGRE_DB_PUSH_PERIODICITY=6000
DAGGRE_GLOBAL_AUTH_TOKEN=$1
DAGGRE_LISTEN_PORT=999
EOF
