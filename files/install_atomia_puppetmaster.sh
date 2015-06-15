#!/bin/bash
echo "Installing Puppet Master"
HOSTNAME=`hostname --fqdn`
DISTNAME=`lsb_release -a | grep Codename: | awk '{print $2}'`
PUPPETURL="https://apt.puppetlabs.com/puppetlabs-release-$DISTNAME.deb"
wget $PUPPETURL
dpkg -i puppetlabs-release-$DISTNAME.deb
rm puppetlabs-release-$DISTNAME.deb
apt-get update
if [ $DISTNAME = "precise"]
then
	apt-get install -y puppetmaster git apache2-utils curl rubygems
	echo "12.04 packages installed... "
elif [ $DISTNAME = "trusty" ]
then
	apt-get install -y puppetmaster git apache2-utils curl rubygems-integration
	echo "14.04 packages installed... 
else
	echo "This Linux version is not supported right now"
fi		
apt-get install -y puppetmaster git apache2-utils curl rubygems
# Following should remove annoying templatedir deprecation warning
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

echo "mod \"atomia\", :git =>\"git://github.com/branislavvukelic/puppet-atomia.git\", :ref => \"master\"" > Puppetfile

service puppetmaster restart
cd /etc/puppet

echo "***** To complete the installation please run the following commands: ****

/bin/bash --login
rvm use 2.1.1
rvm default 2.1.1
cd /etc/puppet
gem install librarian-puppet puppet:3.8.1
librarian-puppet install
cp /etc/puppet/modules/atomia/files/default_files/* /etc/puppet/atomia/service_files/
"
