#!/bin/sh

if [ "$#" -ne 1 ]; then
        echo "Usage: $0 puppetmaster"
        exit 1
fi
hostname=`hostname`

dist=`cat /etc/*-release | egrep ^DISTRIB_CODENAME= | sed 's/.*=//'`
wget http://apt.puppetlabs.com/puppetlabs-release-$dist.deb
sudo dpkg -i puppetlabs-release-$dist.deb
sudo apt-get update
apt-get install -y puppet
apt-get install -y facter

sed -i 's/START=no/START=yes/' /etc/default/puppet

SERVER_CONF=`grep 'ip-10-0-0-52.eu-west-1.compute.internal' /etc/puppet/puppet.conf | wc -l`
if [ $SERVER_CONF -eq 0 ]; then
	sed -i "/\[main\]/a server=$1\nlisten=true" /etc/puppet/puppet.conf
fi
sed -i "/templatedir/d" /etc/puppet/puppet.conf
echo -e 'path /run\nallow *' >> /etc/puppet/auth.conf

service puppet start
PUPPET_RUNNING=`/etc/init.d/puppet status | grep "is running" | wc -l`
if [ $PUPPET_RUNNING -ne 1 ]; then
        echo "Error: Could not start puppet"
        exit 1
fi


puppet agent --enable

#Clean up
rm puppetlabs-release-*.deb
rm bootstrap_linux.sh
