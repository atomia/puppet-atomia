#!/bin/sh

if [ -z "$4" ]; then
	echo "usage: $0 groupname nameserver1 nameserverlist registry"
	exit 1
fi

basedir="/usr/share/doc/atomiadns-masterserver"
if [ -f "$basedir/zones_to_add.txt" ]; then
	zones_to_add=`cat "$basedir/zones_to_add.txt"`

	echo "$zones_to_add" | tr -d " " | tr ";" "\n" | grep -v '^[a-zA-Z0-9.-]$' | while read domain; do
		sudo -u postgres psql zonedata -tA -c "SELECT name FROM zone WHERE name = '$domain'" 2> /dev/null | grep "^$domain"'$' > /dev/null
		if [ $? != 0 ]; then
			echo "$domain not added, will try to restore"
			atomiadnsclient --method AddZone --arg "$domain" --arg 3600 --arg "$2" --arg "$4" --arg 10800 --arg 3600 --arg 604800 --arg 86400 --arg "$3" --arg "$1" 
			if [ $? != 0 ]; then
				echo "error adding, zone, ignoring - it will re-add later anyway"
				exit 0
			else
				touch /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt
			fi
		fi
	done
fi

