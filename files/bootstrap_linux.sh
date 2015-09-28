#!/bin/sh

if [ "$#" -ne 1 ]; then
        echo "Usage: $0 puppetmaster"
        exit 1
fi
hostname=`hostname`
dist=`cat /etc/*-release | egrep ^ID= | sed 's/.*=//'`

if [ "$dist" = "ubuntu" ]; then
        wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
        sudo dpkg -i puppetlabs-release-precise.deb
else
        wget http://apt.puppetlabs.com/puppetlabs-release-wheezy.deb
        dpkg -i puppetlabs-release-wheezy.deb
fi
sudo apt-get update
apt-get install -y puppet

sed -i 's/START=no/START=yes/' /etc/default/puppet
sed -i "/\[main\]/a server=$1\nlisten=true" /etc/puppet/puppet.conf
sed -i "/templatedir/d" /etc/puppet/puppet.conf
echo -e 'path /run\nallow *' >> /etc/puppet/auth.conf

puppet agent --test
if [ "$?" != "0" ]; then
        echo "Error: Could not establish communication with Puppet master"
        exit 1
fi

service puppet start
if [ "$?" != "0" ]; then
        echo "Error: Could not start puppet"
        exit 1
fi


if [ "$dist" = "debian" ]; then
        puppet agent --enable
fi
#Clean up
rm puppetlabs-release-*.deb

