#!/bin/sh

cat <<EOF
hosts = $1
dbname = $2
user = $3
password = $4
query = $5
EOF

