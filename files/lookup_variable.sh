#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
        echo "usage: $0 namespace variable (heira_path) (module_path)"
        exit 1
fi
if [ ! -z "$3" ] 
then
    HIERA_PATH=$3
else
    HIERA_PATH="/etc/puppet/hieradata"
fi

if [ ! -z "$4" ] 
then
    MODULE_PATH=$4
else
    MODULE_PATH="/etc/puppet/modules/atomia/manifests"
fi

NAMESPACE=$1
VARIABLE=$2
TOKEN=`grep -rhi "atomia::${NAMESPACE}::${VARIABLE}" ${HIERA_PATH} | awk '{for(i=2;i<=NF;++i)print $i}' | head -n1 | sed 's/\"//g' | sed "s/\'//g" | tr -d '\n' `
# If token was not found in hiera look for default in module
if [ -z "$TOKEN" ]; then
	TOKEN=`grep -r -i "\\$${VARIABLE}.*=" ${MODULE_PATH}/${NAMESPACE}.pp | head -n1 | grep -Eo '["\047].*["\047]' | sed 's/\"//g' | sed s/\'//g `
fi
echo -n $TOKEN  
