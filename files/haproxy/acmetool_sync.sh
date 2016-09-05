#!/bin/sh

acmetool="/usr/bin/acmetool"
wanted_cert_path="/var/lib/acme/desired"
synced_apache_config="/etc/haproxy/synced_apache_config"
synced_iis_config="/etc/haproxy/synced_iis_config"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "usage: $0 rsync_path_to_apache_config rsync_path_to_iis_config preview_domain"
	echo "example:"
	echo "$0 \"root@192.168.33.21:/storage/configuration/maps\" \"root@192.168.33.21:/storage/configuration/iis\" preview.dev.atomia.com"
	exit 1
fi

# Sync all files from /storage/content/ssl to local dir
rsync -a -e "ssh -o StrictHostKeyChecking=no" --delete "$1"/ "$synced_apache_config"
rsync -a -e "ssh -o StrictHostKeyChecking=no" --delete "$2"/ "$synced_iis_config"

if [ -f "$synced_apache_config/vhost.map" ]; then
	cat "$synced_apache_config"/vhost.map | awk '{ print $1 }' | grep -vE "$3"'$' | grep -v '^www\.' | grep -E '^[a-zA-Z0-9.-]+$' \
			| sort -u | awk '{ print $0 " www." $0 }' | while read cert; do

		if [ ! -f `echo "$wanted_cert_path/$cert"-* | cut -d " " -f 1` ]; then
			$acmetool --batch want $cert > /dev/null 2>&1
		fi
	done
fi

if [ -f "$synced_iis_config/applicationHost.config" ]; then
	grep -F binding "$synced_iis_config/applicationHost.config" | grep -F ":80:" | awk -F ':80:' '{ print $2 }' | cut -d '"' -f 1 \
			| grep -vE "$3"'$' | grep -v '^www\.' | grep -E '^[a-zA-Z0-9.-]+$' | sort -u | awk '{ print $0 " www." $0 }' | while read cert; do

		if [ ! -f `echo "$wanted_cert_path/$cert"-* | cut -d " " -f 1` ]; then
			$acmetool --batch want $cert > /dev/null 2>&1
		fi
	done
fi
