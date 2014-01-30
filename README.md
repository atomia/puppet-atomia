# Getting started #

Deploying this module is done using librarian-puppet https://github.com/rodjek/librarian-puppet

	gem install librarian-puppet
	cd /etc/puppet
	echo "mod \"atomia\", :git://github.com/atomia/puppet-atomia.git\"" > Puppetfile
	librarian-puppet install