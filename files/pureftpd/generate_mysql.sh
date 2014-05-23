#!/bin/sh

cat <<EOF
MYSQLServer     $1
MYSQLSocket      /var/run/mysqld/mysqld.sock
MYSQLUser       $3
MYSQLPassword   $4
MYSQLDatabase   $2
MYSQLCrypt      md5
MYSQLGetPW      SELECT Password FROM users WHERE User="\L" AND status="1"
MYSQLGetUID     SELECT Uid FROM users WHERE User="\L" AND status="1"
MYSQLGetGID     SELECT Gid FROM users WHERE User="\L" AND status="1"
MYSQLGetDir     SELECT Dir FROM users WHERE User="\L" AND status="1"
EOF

