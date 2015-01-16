# Getting started #

Install Puppet Master by running

	wget --no-check-certificate https://raw.github.com/atomia/puppet-atomia/master/files/install_atomia_puppetmaster.sh && chmod +x install_atomia_puppetmaster.sh
	./install_atomia_puppetmaster.sh


If you want to update the Atomia puppet module to the latest supported version simply do

	cd /etc/puppet
	librarian-puppet update

On the Puppet Master generate new certificates for your environment, replace arguments to generate_certificates.rb to fit your environment

	cd /etc/puppet/modules/atomia/files/certificates/
	ruby generate_certificates.rb mydomain.com login order billing hcp

Set up your Active Directory domain according to best practices.

Install a database server with Microsoft SQL Server 2008 R2

## Connect your windows servers to Puppet Master ##

Download and install the latest version of Puppet with the following Powershell commands. Be sure to replace PUPPET_MASTER_SERVER=puppetmaster with your puppetmasters hostname. This can easily be found by going to the puppetmaster and doing "ls /var/lib/puppet/ssl/certs/".

	Dism /online /Enable-Feature /FeatureName:NetFx3 /All
	(new-object System.Net.WebClient).Downloadfile("https://downloads.puppetlabs.com/windows/puppet-3.6.2.msi", "puppet.msi")
	msiexec /qn /i puppet.msi PUPPET_MASTER_SERVER=puppetmaster

Run puppet agent, you will find it on the start menu under puppet -> run puppet agent.

Approve the certificate on the puppet master

	puppet cert list
	puppet cert sign <certname>

## Connect your Linux servers to Puppet Master ##

Run the following script to connect the node to Puppet Master, replace <puppetmaster> with the hostname of your Puppet Master.

	wget --no-check-certificate https://raw.github.com/atomia/installation/master/Files/bootstrap_linux.sh && chmod +x bootstrap_linux.sh
	./bootstrap_linux.sh <puppetmaster>
	rm boostrap_linux.sh

## Configure your hiera data ##

You will find example hiera configurations in the examples/hieradata folder in this repository.

A standard deployment will contain at a minimum 3 files

- common.yaml (variables common to all nodes)
- windows.yaml (variables common to all windows nodes)
- Linux.yaml (variables common to all linux nodes)

You should copy these files from the examples/hieradata folder to your Puppet Master ("/etc/puppet/hieradata"). Fill in the files completely before proceeding.

In order to ease editing of the files there is helper scripts available to run to perform some initial tasks

	/etc/puppet/modules/atomia/files/certificates/set_cert_fingerprints.sh

## Set up accounts in Active Directory ##

On the Puppet Master create a file with the name "/etc/puppet/hieradata/nodes/mydomaincontroller.com.yaml" where mydomaincontroller.com is the certname of your first domain controller. This file should contain the following data:

    ---
    classes:
      - atomia::active_directory

Now run puppet agent on the domain controller to configure it to be used with Atomia.

## Deploying nodes ##

In order to assign a role to a specific node we use facter, there are several ways to add custom facts to facter but the recommended way is to for each node do the following.

	mkdir -p /etc/facter/facts.d
	echo "atomia_role=daggre" >> /etc/facter/facts.d/atomiarole.txt

Replace "atomia_role" with the role you want this node to have. In order for this to work there needs to be a matching yaml file in /etc/puppet/hieradata. Example files for each role can be found at https://github.com/atomia/puppet-atomia/tree/master/examples/hieradata.

A certain order is recommended when you install:

1. Active directory (manual)
2. Atomia database server (manual)
3. Atomia application servers
4. Nagios server
5. AtomiaDNS
6. The remaining agents/resources can be in any order

### Installing Atomia Applications ###

The Atomia applications are deployed on Windows and are using only the windows.yaml data file (with some exceptions). After Puppet has finished it's run on the servers you will have the "Atomia Installer" program on the desktop which is used to install the applications you require on the server.

Some Applications require some extra steps, they are listed below.

**Automation server**

In order to have Puppet deploy resource transformations automatically the server running automation server needs to have the class "atomia::resource_transformations" assigned (no variables need to be passed).


# If you are a developer #

## Running tests ##

Included in the repository is a Vagrant setup which will provision a machine for you which is prepared to run the test suits. Considering you have a working
Vagrant installation simply do:

		vagrant up
		vagrant ssh

Once inside your virtual machine cd to /vagrant and run the tests

Unit tests:

		#Run all tests
		cd /vagrant
		rake spec

		#Run a specific test
		rake spec SPEC=spec/classes/profiles/atomiadns_master_spec.rb

Acceptance tests:

I recommend using our internal OpenStack cloud for running tests, for obvious reasons all required info are not provided in the repo but contact stefan@atomia.com if you think you should be allowed to access it :). The tests can be run with Vagrant as well by configuring a vagrant nodeset.

When you got your nodes set up run the tests with

		bundle exec rspec spec/acceptance/atomiadns_spec.pp
