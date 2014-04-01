[![Build Status](https://travis-ci.org/atomia/puppet-atomia.svg?branch=master)](https://travis-ci.org/atomia/puppet-atomia)

# Getting started - The quick and dirty version #

Install Puppet with Hiera

	wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
	dpkg -i puppetlabs-release-precise.deb
	apt-get update
	apt-get install puppetmaster git apache2-utils
	mkdir /etc/puppet/hieradata
    
Install Ruby 1.9.3
    apt-get install curl
    curl -sSL https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm install 1.9.3
    rvm default 1.9.3

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

Make sure your /etc/puppet/manifests/site.pp file contains the following

	node default {
	        hiera_include('classes')
	}

Add the following to /etc/puppet/fileserver.conf

	[atomiacerts]
 	   path /etc/puppet/atomiacerts
  	   allow *

Deploying the atomia module is done using librarian-puppet https://github.com/rodjek/librarian-puppet

	gem install librarian-puppet
	cd /etc/puppet
	echo "mod \"atomia\", :git =>\"git://github.com/atomia/puppet-atomia.git\"" > Puppetfile
	librarian-puppet install 
	
If you want to update your modules to the latest supported version simply do

	cd /etc/puppet
	librarian-puppet update

Generate new certificates for your environment, replace arguments to generate_certificates.rb to fit your environment

	cd /etc/puppet/modules/atomia/files/certificates/
	ruby generate_certificates.rb mydomain.com login order billing my

Set up your Active Directory domain according to best practices.

Install a database server with Microsoft SQL Server 2008 R2

Add apppooluser, PosixGuest and WindowsAdmin to Active directory,
apppooluser needs to have the logon as a service right and both WindowsAdmin and apppooluser needs Domain admin privileges

**Connect your windows servers to Puppet Master**

Download and install the latest version of Puppet with the following Powershell commands. Be sure to replace PUPPET_MASTER_SERVER=puppetmaster with your puppetmasters hostname. This can easily be found by going to the puppetmaster and doing "ls /var/lib/puppet/ssl/certs/".

	(new-object System.Net.WebClient).Downloadfile("https://downloads.puppetlabs.com/windows/puppet-3.3.2.msi", "puppet.msi") msiexec /qn /i puppet.msi PUPPET_MASTER_SERVER=puppetmaster

Run puppet agent, you will find it on the start menu under puppet -> run puppet agent.

Approve the certificate on the puppet master

	puppet cert list
	puppet cert sign <certname>

**Connect your Linux servers to Puppet Master**

Run the following script to connect the node to Puppet Master, replace <puppetmaster> with the hostname of your Puppet Master.

	wget --no-check-certificate https://raw.github.com/atomia/installation/master/Files/bootstrap_linux.sh && chmod +x bootstrap_linux.sh
	./bootstrap_linux.sh <puppetmaster>
	rm boostrap_linux.sh

**Configure your hiera data**

You will find example hiera configurations in the examples/hieradata folder in this repository. 

A standard deployment will contain at a minimum 3 files

- common.yaml (variables common to all nodes)
- windows.yaml (variables common to all windows nodes)
- linux.yaml (variables common to all linux nodes)

The data in these files can be overridden by using the facts $fqdn, $atomia_brand and $atomia_role 

Start with copying these three files to /etc/puppet/hieradata on the Puppet Master.

In order to ease editing of these files there is helper scripts available to run to perform some initial tasks

	/etc/puppet/modules/atomia/files/certificates/set_cert_fingerprints.sh

You should now edit the variables in these files to fit your environment

In order to assign a role to a specific node we use facter, there are several ways to add custom facts to facter but the recommended way is to for each node do the following.

	mkdir -p /etc/facter/facts.d
	echo "atomia_role=daggre" >> /etc/facter/facts.d/atomiarole.txt

Replace "atomia_role" with the role you want this node to have. In order for this to work there needs to be a matching yaml file in /etc/puppet/hieradata. Example files for each role can be found at https://github.com/atomia/puppet-atomia/tree/master/examples/hieradata

