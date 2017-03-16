#!/bin/sh

PATH="/bin:/usr/bin:/usr/sbin"

command="$1"
volume=`echo "$2" | sed -s 's/[^a-z_]//g'`
user=`echo "$3" | sed -e 's/[^0-9]//g'`
quota=`echo "$4" | sed -e 's/[^0-9]//g'`

unlimited_quota=`if [ x"$4" = x"-1" ]; then echo "1"; else echo "0"; fi`

if !([ x"$command" = x"add" ] || [ x"$command" = x"remove" ]) || [ -z "$user" ] || [ -x "$volume" ] || \
		([ x"$command" = x"add" ] && [ -z "$quota" ]); then
	echo "usage: $0 command volume user quotavalue"
	echo "examples:"
	echo "$0 add 100008 1048576"
	echo "$0 remove 100008"
	exit 1
fi

path=`echo "$user" | sed -e 's,^[0-9]*\([0-9][0-9]\)$,/\1/\0,'`

if [ x"$command" = x"add" ]; then
	if [ x"$unlimited_quota" = x"1" ]; then
		echo "treating -1 as unlimited by not setting quota"
		exit 0
	fi

	mail_volume_path="/storage/mailcontent"
	if [ x"$volume" = x"mail_volume" ] && [ -d "$mail_volume_path" ]; then
		[ -d "$mail_volume_path/$path" ] || {
			mkdir -p "$mail_volume_path/$path"
			chown 2000:2000 "$mail_volume_path/$path"
			chmod 700 "$mail_volume_path/$path"
		}
	fi

	output=`gluster volume quota "$volume" limit-usage "$path" "$quota" 2>&1`
	echo "$output"
	echo "$output" | grep -iE "success|limit set" > /dev/null
elif [ x"$command" = x"remove" ]; then
	output=`gluster volume quota "$volume" remove "$path" 2>&1`
	echo "$output"
	echo "$output" | grep -iE "success|removed quota|no limit set|No such file|No data available" > /dev/null
else
	echo "unknown command $command"
	exit 1
fi
