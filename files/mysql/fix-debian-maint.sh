#!/bin/sh
mysql_command="mysql --defaults-file=/etc/mysql/debian.cnf -Ns"
command=`$mysql_command -e "show columns from user like '%_priv'" mysql | /bin/grep enum | /usr/bin/cut -f1 | /usr/bin/awk '{ print $1, "= '\'Y\''" }' | /usr/bin/paste -sd ','`

$mysql_command -e "UPDATE user SET $command WHERE User = 'debian-sys-maint' AND Host = 'localhost'; FLUSH PRIVILEGES;" mysql
