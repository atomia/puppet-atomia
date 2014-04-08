#!/bin/sh

if [ -z "$1" ]; then
        echo "Usage: $0 domain"
        exit 1
fi

domain="$1"

check=`domainreg_client --method DomainCheck --arg $domain | grep -o successful `

if [ "$check" = "successful" ]; then
        echo "OK: Domain check executed successfully for $domain"
        exit 0
else
        echo "CRITICAL: Domain check unsuccessful for $domain"
        exit 2
fi
