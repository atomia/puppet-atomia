# Getting started #

Install Puppet with Hiera

	wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
	dpkg -i puppetlabs-release-precise.deb
	apt-get update
	apt-get install puppetmaster
	puppet resource package hiera ensure=installed
	puppet resource package hiera-puppet ensure=installed
	mkdir /etc/puppet/hieradata

Create a new hiera.yaml file in /etc/puppet/hiera.yaml with the following content

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


Deploying the atomia module is done using librarian-puppet https://github.com/rodjek/librarian-puppet

	gem install librarian-puppet
	cd /etc/puppet
	echo "mod \"atomia\", :git =>\"git://github.com/atomia/puppet-atomia.git\"" > Puppetfile
	librarian-puppet install && cd modules/atomia && librarian-puppet install --path /etc/puppet/modules/ && cd ../../



