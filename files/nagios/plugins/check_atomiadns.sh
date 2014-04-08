#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
	echo "usage: $0 zone url user pass"
	exit 1
fi

zone="$1"
url="$2"
user="$3"
pass="$4"

output=`atomiadnsclient --uri "$url" --username "$user" --password "$pass" --method GetDnsRecords --arg "$zone" --arg "@" | grep SOA | wc -l | tr -d " "`
if [ x"$output" = x"1" ]; then
	echo "OK: Exactly 1 SOA fetched for zone $zone"
	exit 0
else
	echo "CRITICAL: Number of SOA records fetched for zone $zone didn't match 1 "
	exit 2
fi
