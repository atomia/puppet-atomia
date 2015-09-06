#!/bin/bash
# Author   : Branislav Vukelic
# Revision : 1
# Date     : 2015-08-05
#
# Notes:
# This script will take your current network information 
# and create a static configuration for private network adapter (eth0)
#
# Installation:
# Save this file as /root/static.sh
# Make the file executable # chmod a+x /root/static.sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
	echo "Usage: $0 Hostname LocalDomain DC_address Puppet_address"
	exit 1
else
	ATOMIA_HOSTNAME="$1"
	ATOMIA_LOC_DOMAIN="$2"
	ATOMIA_DC="$3"
	ATOMIA_PUPPET="$4"
fi

# Code

OS=`cat /etc/issue | sed 's/\(\w\) .*/\1/'`

case "$OS" in
	Red*)
		OS=RH
		;;
	Cen*)
		OS=RH
		;;
	Deb*)
		OS=Deb
		;;
	Ubu*)
		OS=Deb
		;;
	*)
		OS=Unknown
		;;
esac

# Make backups
BACKUPDIR=/root/`date +%F`-backup
[[ -d $BACKUPDIR || -f $BACKUPDIR ]]  && rm -rf $BACKUPDIR
mkdir $BACKUPDIR
[[ ! -d $BACKUPDIR ]] && exit 1

if [ -d /etc/network ] ; then
	NETCFG=/etc/network
	cp $NETCFG/interfaces $BACKUPDIR/interfaces.bak
fi

cp /etc/resolv.conf $BACKUPDIR/resolv.bak
cp /etc/hosts $BACKUPDIR/hosts.bak

# Get netstat information
[[ -f /tmp/netstat.tmp ]] && rm -f /tmp/netstat.tmp
/bin/netstat -nar | grep eth0 > /tmp/netstat.tmp
sed -i '/169.254.0.0/d' /tmp/netstat.tmp

# MAC - Get MAC addresses for eth0 interface
[[ -f /tmp/eth0.mac.tmp ]] && rm -f /tmp/eth0.mac.tmp
/sbin/ifconfig eth0 | grep "HWaddr" | sed 's/.* HWaddr //' > /tmp/eth0.mac.tmp

# PUBLIC - Get the current IP
[[ -f /tmp/eth0.ip.tmp ]] && rm -f /tmp/eth0.ip.tmp
/sbin/ifconfig eth0 | grep "inet addr" | sed 's/.* addr://;s/[ \t]* .*//' > /tmp/eth0.ip.tmp

# NETWORK - Get the network IP
[[ -f /tmp/eth0.network.tmp ]] && rm -f /tmp/eth0.network.tmp
cp /tmp/netstat.tmp /tmp/eth0.network.tmp
sed -i '/UG/d;s/[ \t]* .*//' /tmp/eth0.network.tmp

# GATEWAY - Get the gateway IP
[[ -f /tmp/eth0.gateway.tmp ]] && rm -f /tmp/eth0.gateway.tmp
cp /tmp/netstat.tmp /tmp/eth0.gateway.tmp
sed -i '/[1-9]* .* U .*/d;s/0.0.0.0[ \t]*//;s/[ \t]* .*//' /tmp/eth0.gateway.tmp

# NETMASK - Get the network netmask
[[ -f /tmp/eth0.netmask.tmp ]] && rm -f /tmp/eth0.netmask.tmp
/sbin/ifconfig eth0 | grep Mask | sed 's/.* Mask://' > /tmp/eth0.netmask.tmp


# Assign variables from temp files
HWADDR0=`cat /tmp/eth0.mac.tmp`
ADDRES0=`cat /tmp/eth0.ip.tmp`
GATEWAY=`cat /tmp/eth0.gateway.tmp`
NETWORK=`cat /tmp/eth0.network.tmp`
NETMASK=`cat /tmp/eth0.netmask.tmp`

if [ $OS = RH ] ; then
	echo "$OS is currently unsupported."; exit 1;

elif [ $OS = Deb ] ; then
	/etc/init.d/networking stop
	sleep 1
	# Build /etc/network/interfaces
	[[ -f /etc/network/interfaces ]] && rm -f /etc/network/interfaces
	cat > /etc/network/interfaces <<CFGINTERFACES
# This file describes network interfaces avaiulable on your system
# and how to activate them. For more information, see interfaces(5).
# Modified by static.sh

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address $ADDRES0
	hwaddress ether $HWADDR0
	netmask $NETMASK
	network $NETWORK
	gateway $GATEWAY
	dns-nameservers $ATOMIA_DC
	dns-search $ATOMIA_LOC_DOMAIN

# Add static IP for Public interface if exist
# auto eth1
# iface eth1 inet static
# address 1.1.1.1
# netmask 255.255.255.0
CFGINTERFACES

	# Build /etc/hosts and /etc/hostname
	echo -e "$ATOMIA_HOSTNAME" > /etc/hostname
	hostname $ATOMIA_HOSTNAME
	echo $ATOMIA_HOSTNAME > /proc/sys/kernel/hostname
	rm -rf /etc/hosts
	echo -e "127.0.0.1\tlocalhost" > /etc/hosts
	echo -e "$ADDRES0\t$ATOMIA_HOSTNAME.$ATOMIA_LOC_DOMAIN $ATOMIA_HOSTNAME" >> /etc/hosts 
	echo -e "$ATOMIA_PUPPET\tpuppet.$ATOMIA_LOC_DOMAIN puppet" >> /etc/hosts 

	# Clear and rebuild /etc/resolv.comf
#	echo "" > /etc/resolv.conf
#	resolvconf -u

	# Start network	
	/etc/init.d/networking start
else
	echo "$OS is unsupported."; exit 1;
fi

# Remove temp files
rm -rf /tmp/*.tmp