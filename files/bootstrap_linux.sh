#!/bin/sh

if [ "$#" -ne 1 ]; then
        echo "Usage: $0 puppetmaster"
        exit 1
fi
hostname=`hostname`

dist=`cat /etc/*-release | egrep ^DISTRIB_CODENAME= | sed 's/.*=//'`
PUPPET_INSTALLED=`dpkg -l puppet | grep puppetlabs | wc -l`
if [ $PUPPET_INSTALLED -eq 0 ]; then
	wget http://apt.puppetlabs.com/puppetlabs-release-$dist.deb
	sudo dpkg -i puppetlabs-release-$dist.deb
	sudo apt-get update
	apt-get install -y puppet
	apt-get install -y facter
	sed -i 's/START=no/START=yes/' /etc/default/puppet
fi

SERVER_CONF=`grep '$1' /etc/puppet/puppet.conf | wc -l`
if [ $SERVER_CONF -eq 0 ]; then
	sed -i "/\[main\]/a server=$1\nlisten=true" /etc/puppet/puppet.conf
	sed -i "/templatedir/d" /etc/puppet/puppet.conf
	echo -e 'path /run\nallow *' >> /etc/puppet/auth.conf
	puppet agent --enable
	service puppet stop
fi

#Clean up
rm puppetlabs-release-*.deb
rm bootstrap_linux.sh
