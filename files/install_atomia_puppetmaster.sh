#!/bin/bash
echo "Installing Puppet Master"
HOSTNAME=`hostname --fqdn`
wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
rm puppetlabs-release-precise.deb
apt-get update
apt-get install -y puppetmaster git apache2-utils curl rubygems
cd /etc/puppet
puppet resource package puppetdb ensure=latest
puppet resource service puppetdb ensure=running enable=true
puppet resource package puppetdb-terminus ensure=latest
mkdir /etc/puppet/hieradata


echo "
:backends:
  - yaml
:hierarchy:
  - "nodes/%{::fqdn}"
  - "%{::atomia_role}"
  - "%{::atomia_brand}_common"
  - "%{::kernel}"
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
" >> /etc/puppet/fileserver.conf


echo "
[main]
server = $HOSTNAME
port = 8081
" > /etc/puppet/puppetdb.conf

echo "
[master]
storeconfigs = true
storeconfigs_backend = puppetdb
" >> /etc/puppet.conf

echo "
---
master:
   facts:
      terminus: puppetdb
      cache: yaml
" >  /etc/puppet/routes.yaml

curl -sSL https://get.rvm.io | bash -s stable


source "/usr/local/rvm/scripts/rvm"
/usr/local/rvm/bin/rvm install 2.1.1

echo "mod \"atomia\", :git =>\"git://github.com/atomia/puppet-atomia.git\"" > Puppetfile

service puppetmaster restart
cd /etc/puppet

echo "***** To complete the installation please run the following commands: ****

/bin/bash --login
rvm use 2.1.1
rvm default 2.1.1
cd /etc/puppet
gem install librarian-puppet puppet
librarian-puppet install"
