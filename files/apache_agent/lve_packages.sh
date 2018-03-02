#!/bin/bash

PDIR="/storage/configuration/cloudlinux"
cd $PDIR

case "$1" in
        --list-all)

                cat lve_packages

        ;;
        --userid=*)
                uid=${1#*=}
                cat lve_packages | grep $uid | awk '{ print $2 }'
        ;;
        --package=*)
                pack=${1#*=}
                cat lve_packages | grep $pack | awk '{ print $1 }'
        ;;
        --list-packages)
                cat lve_packages | awk '{ print $2 }' | sort | uniq
        ;;
        --list-resellers-packages)
                echo " "
        ;;
        *)
                echo "Usage:
--help               show this message
--list-all           prints <userid package> pairs (accepts no parameters);
--userid=id          prints package for a user specified
--package=package    prints users for a package specified
--list-packages      prints packages list"
        ;;
esac
