# Puppet Atomia

[![Build Status](https://travis-ci.org/atomia/puppet-atomia.svg?branch=master)](https://travis-ci.org/atomia/puppet-atomia)

This Puppet Module is used to deploy and configure a complete Atomia environment. It is supposed to be used in conjunction with our [Puppetmaster GUI](https://github.com/atomia/puppetmaster-gui). You can find installation instructions [here](https://github.com/atomia/puppetmaster-gui/wiki/Installing-a-production-environment).


All contributions are welcome and are preferably done via Issue reports and or Pull requests.

## Enable Quota feature for Mail Account

To enable quota feature for Mail Accounts you need to execute /etc/postfix/update_vmail_database_for_quota.sql on postfix machine which will update user table in vmail database to contain necessary columns.
