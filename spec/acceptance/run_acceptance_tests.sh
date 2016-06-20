#/bin/bash

if [ "$1" == "default" ]; then
    export BEAKER_set="ubuntu-14.04-amd64"
    bundle exec rspec spec/acceptance/atomiadns_acceptance.pp spec/acceptance/atomia_database_acceptance.pp
fi

if [ "$1" == "ubuntu-12-04" ]; then
    export BEAKER_set="ubuntu-12.04-amd64"
    bundle exec rspec spec/acceptance/domainreg_acceptance.pp
fi