# Getting started #

Install Puppet Master by running 

	wget --no-check-certificate https://raw.github.com/atomia/puppet-atomia/master/files/install_atomia_puppetmaster.sh && chmod +x install_atomia_puppetmaster.sh
	./install_atomia_puppetmaster.sh

	
If you want to update the Atomia puppet module to the latest supported version simply do

	cd /etc/puppet
	librarian-puppet update

On the Puppet Master generate new certificates for your environment, replace arguments to generate_certificates.rb to fit your environment

	cd /etc/puppet/modules/atomia/files/certificates/
	ruby generate_certificates.rb mydomain.com login order billing my

Set up your Active Directory domain according to best practices.

Install a database server with Microsoft SQL Server 2008 R2

**Connect your windows servers to Puppet Master**

Download and install the latest version of Puppet with the following Powershell commands. Be sure to replace PUPPET_MASTER_SERVER=puppetmaster with your puppetmasters hostname. This can easily be found by going to the puppetmaster and doing "ls /var/lib/puppet/ssl/certs/".

	Dism /online /Enable-Feature /FeatureName:NetFx3 /All
	(new-object System.Net.WebClient).Downloadfile("https://downloads.puppetlabs.com/windows/puppet-3.3.2.msi", "puppet.msi") 
	msiexec /qn /i puppet.msi PUPPET_MASTER_SERVER=puppetmaster

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
- Linux.yaml (variables common to all linux nodes)

You should copy these files from the examples/hieradata folder to your Puppet Master ("/etc/puppet/hieradata"). Fill in the files completely before proceeding.

In order to ease editing of these files there is helper scripts available to run to perform some initial tasks

	/etc/puppet/modules/atomia/files/certificates/set_cert_fingerprints.sh

**Set up accounts in Active Directory**

On the Puppet Master create a file with the name "/etc/puppet/hieradata/nodes/MainDomainController.yaml" where MainDomainController is the hostname of your first domain controller. This file should contain the following data:

    ---
    classes:
      - atomia::active_directory

Now run puppet agent on the domain controller to configure it to be used with Atomia.

**Deploying nodes**

In order to assign a role to a specific node we use facter, there are several ways to add custom facts to facter but the recommended way is to for each node do the following.

	mkdir -p /etc/facter/facts.d
	echo "atomia_role=daggre" >> /etc/facter/facts.d/atomiarole.txt

Replace "atomia_role" with the role you want this node to have. In order for this to work there needs to be a matching yaml file in /etc/puppet/hieradata. Example files for each role can be found at https://github.com/atomia/puppet-atomia/tree/master/examples/hieradata


