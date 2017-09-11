#!/bin/bash

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 Puppet PuppetIP Server ServerIP"
	exit 1
else
	PUPPET_HOSTNAME="$1"
	PUPPET_IP="$2"
	SERVER_HOSTNAME="$3"
	SERVER_IP="$4"
fi

setuppuppetresolving()
{
PUPPET_HOSTNAME_SHORT=`echo ${PUPPET_HOSTNAME} | cut -d . -f 1`
# Build /etc/hosts
sed -i "/${PUPPET_HOSTNAME}/d" /etc/hosts
echo -e "${PUPPET_IP}\t${PUPPET_HOSTNAME} ${PUPPET_HOSTNAME_SHORT}" >> /etc/hosts 
}

setupserverresolving()
{
SERVER_HOSTNAME_SHORT=`echo ${SERVER_HOSTNAME} | cut -d . -f 1`
# Build /etc/hosts
sed -i "/${SERVER_HOSTNAME}/d" /etc/hosts
echo -e "${SERVER_IP}\t${SERVER_HOSTNAME} ${SERVER_HOSTNAME_SHORT}" >> /etc/hosts 
}

setuphostname()
{
# Build /etc/hostname
echo -e "${SERVER_HOSTNAME}" > /etc/hostname
hostname ${SERVER_HOSTNAME}
echo ${SERVER_HOSTNAME} > /proc/sys/kernel/hostname
}

installpuppet()
{
if [ -e '/etc/debian_version' ]; then
	dist=`cat /etc/*-release | egrep ^DISTRIB_CODENAME= | sed 's/.*=//'`
	PUPPET_INSTALLED=`dpkg -l puppet | grep puppetlabs | wc -l`
	if [ $PUPPET_INSTALLED -eq 0 ]; then
		sudo apt-get update
		if [ `lsb_release -r | awk '{print $2}'` == '14.04' ]; then
			wget http://apt.puppetlabs.com/puppet-release-$dist.deb
			sudo dpkg -i puppet-release-$dist.deb
			apt-get install -y facter
			sed -i 's/START=no/START=yes/' /etc/default/puppet
			rm -f puppet-release-*.deb
		else
			apt-get install -y puppet
			apt-get install -y facter
		fi
	fi
elif [ -e '/etc/redhat-release' ]; then
	for os_release in redhat-release centos-release cloudlinux-release; do
		if rpm -q --quiet $os_release; then
			major_version=$(rpm -q --queryformat '%{VERSION}' $os_release|cut -d. -f1)
		fi
	done
		if ! rpm -q --quiet puppet puppetlabs-release; then
			rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-$major_version.noarch.rpm
			yum install puppet puppetlabs-release -y && chkconfig puppet off
		fi
fi

SERVER_CONF=`grep ${PUPPET_HOSTNAME} /etc/puppet/puppet.conf | wc -l`
if [ $SERVER_CONF -eq 0 ]; then
	sed -i "/\[main\]/a server=${PUPPET_HOSTNAME}\nlisten=true" /etc/puppet/puppet.conf
	sed -i "/templatedir/d" /etc/puppet/puppet.conf
	echo -e 'path /run\nallow *' >> /etc/puppet/auth.conf
	puppet agent --enable
	service puppet stop
fi
}

# Check if puppet is resolvable and add it to hosts file if not
if [ -z `getent hosts ${PUPPET_HOSTNAME} | awk '{print $1}'` ] || [ "$(getent hosts ${PUPPET_HOSTNAME} | awk '{print $1}')" != "${PUPPET_IP}" ]; then
	setuppuppetresolving
	else
	echo -e "Puppetmaster resolving already in place"
	echo -e "=========="
	cat /etc/hosts
	echo -e "=========="
fi

# Check if server is resolvable and add it to hosts file if not
if [ -z `getent hosts ${SERVER_HOSTNAME} | awk '{print $1}'` ] || [ "$(getent hosts ${SERVER_HOSTNAME} | awk '{print $1}')" != "${SERVER_IP}" ]; then
	setupserverresolving
	else
	echo -e "Server resolving already in place"
	echo -e "=========="
	cat /etc/hosts
	echo -e "=========="
fi

# Check is hostname ok and fix it if not
if [ "$(hostname -f)" != "${SERVER_HOSTNAME}" ]; then
	setuphostname
fi

# Install puppet agent
installpuppet

#Clean up
rm bootstrap_linux.sh
echo "Done with bootstrap process !!!"
