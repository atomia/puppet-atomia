#!/bin/sh

if [ "$#" -ne 1 ]; then
        echo "Usage: $0 puppetmaster"
        exit 1
fi
hostname=`hostname`

if [ -e '/etc/debian_version' ]; then
        dist=`cat /etc/*-release | egrep ^DISTRIB_CODENAME= | sed 's/.*=//'`
        PUPPET_INSTALLED=`dpkg -l puppet | grep puppetlabs | wc -l`
        if [ $PUPPET_INSTALLED -eq 0 ]; then
                wget http://apt.puppetlabs.com/puppetlabs-release-$dist.deb
                sudo dpkg -i puppetlabs-release-$dist.deb
                sudo apt-get update
                apt-get install -y puppet
                apt-get install -y facter
                sed -i 's/START=no/START=yes/' /etc/default/puppet
                rm puppetlabs-release-*.deb
        fi
elif [ -e '/etc/redhat-release' ]; then
	for os_release in redhat-release centos-release cloudlinux-release; do
		if rpm -q --quiet $os_release; then
			major_version=$(rpm -q --queryformat '%{VERSION}' $os_release)
		fi
	done
        if ! rpm -q --quiet puppet puppetlabs-release; then
                rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-$major_version.noarch.rpm
                yum install puppet puppetlabs-release -y && chkconfig puppet off
        fi
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
rm bootstrap_linux.sh
echo "Done with bootstrap.sh"
