#!/bin/bash
# Define some colors for readability
 
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32m"

echo -e "$COL_GREEN Installing Puppet Master $COL_RESET"
HOSTNAME=`hostname --fqdn`
DISTNAME=`lsb_release -a | grep Codename: | awk '{print $2}'`
PUPPETURL="https://apt.puppetlabs.com/puppetlabs-release-$DISTNAME.deb"
wget $PUPPETURL
dpkg -i puppetlabs-release-$DISTNAME.deb
rm puppetlabs-release-$DISTNAME.deb
apt-get update
#
# Adding packages for correct Ubuntu version
#
if [ $DISTNAME = "precise" ]
then
	apt-get install -y puppetmaster git apache2-utils curl rubygems
	echo -e "$COL_GREEN 12.04 packages installed... $COL_RESET"
elif [ $DISTNAME = "trusty" ]
then
	apt-get install -y puppetmaster git apache2-utils curl rubygems-integration
	echo -e "$COL_GREEN 14.04 packages installed... $COL_RESET"
else
	echo -e "$COL_RED This Linux version is not supported right now $COL_RESET"
fi
#
# Following line should remove annoying templatedir deprecation warning
#
sed -i "/templatedir/d" /etc/puppet/puppet.conf
cd /etc/puppet
puppet resource package puppetdb ensure=latest
puppet resource service puppetdb ensure=running enable=true
puppet resource package puppetdb-terminus ensure=latest
mkdir /etc/puppet/hieradata


echo -e "
:backends:
  - yaml
:hierarchy:
  - \"nodes/%{::fqdn}\"
  - \"%{::atomia_role}\"
  - \"%{::atomia_brand}_common\"
  - \"%{::kernel}\"
  - common
:yaml:
  :datadir: /etc/puppet/hieradata
" > /etc/puppet/hiera.yaml

echo "
node default {
        hiera_include('classes')
}
" > /etc/puppet/manifests/site.pp

echo "
[atomiacerts]
   path /etc/puppet/atomiacerts
   allow *

[atomia]
   path /etc/puppet/atomia
   allow *

" >> /etc/puppet/fileserver.conf

mkdir -p /etc/puppet/atomia/service_files

echo "
[main]
server = $HOSTNAME
port = 8081
" > /etc/puppet/puppetdb.conf

echo "
storeconfigs = true
storeconfigs_backend = puppetdb
" >> /etc/puppet/puppet.conf

echo "
---
master:
   facts:
      terminus: puppetdb
      cache: yaml
" >  /etc/puppet/routes.yaml

curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable


source "/usr/local/rvm/scripts/rvm"
/usr/local/rvm/bin/rvm install 2.1.1

echo "mod \"atomia\", :git =>\"git://github.com/atomia/puppet-atomia.git\", :ref => \"stable\"" > Puppetfile

service puppetmaster restart
cd /etc/puppet

echo "***** To complete the installation please run the following commands: ****

/bin/bash --login
rvm use 2.1.1
rvm default 2.1.1
cd /etc/puppet
gem install librarian-puppet puppet:3.8.2
librarian-puppet install
cp /etc/puppet/modules/atomia/files/default_files/* /etc/puppet/atomia/service_files/
"
