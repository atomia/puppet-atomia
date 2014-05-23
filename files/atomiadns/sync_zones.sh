#!/bin/sh

if [ -z "$1" ]; then
	echo "usage: $0 groupname"
	exit 1
fi

basedir="/usr/share/doc/atomiadns-masterserver"
if [ -f "$basedir/zones_to_add.txt" ] && [ -f "$basedir/zone_content_to_add.txt" ]; then
	zones_to_add=`cat "$basedir/zones_to_add.txt"`
	zone_content_to_add=`cat "$basedir/zone_content_to_add.txt"`

	echo "$zones_to_add" | tr -d " " | tr ";" "\n" | grep -v '^[a-zA-Z0-9.-]$' | while read domain; do
		sudo -u postgres psql zonedata -tA -c "SELECT name FROM zone WHERE name = '$domain'" 2> /dev/null | grep "^$domain"'$' > /dev/null
		if [ $? != 0 ]; then
			echo "$domain not added, will try to restore"
			content=`echo "$zone_content_to_add" | grep "^$domain=" | cut -d "=" -f 2- | tr ";" "\n" | tr -s "\n"`
			atomiadnsclient --method RestoreZoneBinary --arg "$domain" --arg "$1" --arg "$content"
			if [ $? != 0 ]; then
				echo "error adding, zone, ignoring - it will re-add later anyway"
				exit 0
			else
				touch /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt
			fi
		fi
	done
fi

