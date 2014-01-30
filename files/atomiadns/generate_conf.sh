#!/bin/sh

if [ x"$5" = x"ssl" ]; then
	ssl="soap_cacert = /etc/atomiadns-mastercert.pem"
else
	ssl=";soap_cacert = /etc/atomiadns-mastercert.pem"
fi 

cat <<EOF
soap_uri = $4
soap_username = $1
soap_password = $2
$ssl
servername = $3
EOF

