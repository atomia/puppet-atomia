#!/bin/bash
# 
# Branislav Vukelic <branislav@atomia.com>
#
clear

# Define some colors for readability
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32m"

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Usage: $0 hostname IPaddress (where hostname is one of proposed by installation documentation, and IPaddress is puppetmaster IP)"
	echo "==========="
	echo "eg: apacheXX, mailXX, nsXX, ftpXX..."
	echo "==========="	
	echo "(XX is two digit number from 01 to 10)"
	exit 1
else
	ATOMIA_HOSTNAME="$1"
	ATOMIA_PUPPETMASTER="$2"
fi

apt-get install -y sshpass

sshpass -p 'password' scp -oStrictHostKeyChecking=no installuser@"$ATOMIA_PUPPETMASTER":/etc/puppet/hieradata/nodes/config.lan config.lan
if (( $? )); then
  echo -e $COL_RED "Retrieving template files from PUPPETMASTER failed... " $COL_RESET >&2
  exit 1
else

LIST="config.lan"

# Assign variables from temp files
HOSTNAME=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f1`
FQDN=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f2`
ADDRESS=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f3`
NETWORK=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f4`
NETMASK=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f5`
GATEWAY=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f6`
NAMESERVERS=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f7`
SEARCH=`egrep "^$ATOMIA_HOSTNAME" $LIST | cut -d, -f2 | cut -d. -f2-`

echo -e "FQDN is $COL_GREEN $FQDN" $COL_RESET
echo -e "Address is $COL_GREEN $ADDRESS" $COL_RESET

/etc/init.d/networking stop
sleep 1
# Build /etc/network/interfaces
[[ -f /etc/network/interfaces ]] && rm -f /etc/network/interfaces
cat > /etc/network/interfaces <<INTERFACE0
# This file describes network interfaces avaiulable on your system
# and how to activate them. For more information, see interfaces(5).
# Modified by static.sh

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address $ADDRESS
	netmask $NETMASK
	network $NETWORK
	gateway $GATEWAY
	dns-nameservers $NAMESERVERS
	dns-search $SEARCH

# Add static IP for Public interface if exist
# auto eth1
# iface eth1 inet static
# address 1.1.1.1
# netmask 255.255.255.0
INTERFACE0

# Build /etc/hosts and /etc/hostname
echo -e "$HOSTNAME" > /etc/hostname
hostname $HOSTNAME
echo $HOSTNAME > /proc/sys/kernel/hostname
rm -rf /etc/hosts
echo -e "127.0.0.1\tlocalhost" > /etc/hosts
echo -e "$ADDRESS\t$FQDN $HOSTNAME" >> /etc/hosts 
echo -e "$ATOMIA_PUPPETMASTER\tpuppet.$SEARCH puppet" >> /etc/hosts 

# Start network	
/etc/init.d/networking start
echo -e $COL_GREEN "Basic Linux setup configured !!! " $COL_RESET
echo "==="
echo -e $COL_GREEN "Rebooting... " $COL_RESET
fi
reboot

exit 0