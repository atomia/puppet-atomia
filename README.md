# Puppet Atomia #

We are in the process of rewriting this module in order to improve the installation process.
New instructions are coming once this is done. To install using the old procedure please use the stable branch.

## Installation instructions (WORK IN PROGRESS) ##

### Setup PuppetMaster and the installation GUI ###
The preferred way of installation is using our installation GUI which will guide you through the whole process.

1. Do a standard installation of Ubuntu 14.04
2. Become root
3. Add the Atomia APT Repository to the server
		repo="$(wget -q -O - http://public.apt.atomia.com/setup.sh.shtml | sed s/%distcode/`lsb_release -c | awk '{ print $2 }'`/g)"; echo "$repo" | sh
4. Install the atomia puppetmaster package
		apt-get install atomia-puppetmaster
5. Finalize the setup by running the command
		setup-puppet-atomia
