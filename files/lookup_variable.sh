#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
        echo "usage: $0 namespace variable"
        exit 1
fi
HIERA_PATH="/etc/puppet/hieradata"
MODULE_PATH="/etc/puppet/modules/atomia/manifests"
NAMESPACE=$1
VARIABLE=$2

MODULE_PATH="/vagrant/modules/atomia/manifests"

TOKEN=`grep -r -i "atomia::${NAMESPACE}::${VARIABLE}" ${HIERA_PATH} | awk '{print $2}' | sed 's/\"//g' | sed "s/\'//g"`

# If token was not find in hiera look for default in module
if [ -z "$TOKEN" ]; then
	TOKEN=`grep -r -i ${VARIABLE} ${MODULE_PATH}/${NAMESPACE}.pp | sed 's/.* =//' | sed 's/\,//'|tr -d ' ' `
fi

echo $TOKEN
