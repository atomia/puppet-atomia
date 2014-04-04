#!/bin/sh

PACKAGE=`atomia package list --account 100000  | grep current | head -n1 | sed 's/\"//g' | sed 's/://' | sed 's/,//' | tr -d ' '`

# Does not contain any packages
if [ "$PACKAGE" != "current_request_id" ]
then
        atomia package add --account 100000 --packagedata '{"package_name": "BasePackage", "package_arguments" : { "ADPassword": "7DSmHPUL", "FtpPassword": "Abc123", "PosixUid": "100000", "RootFolderParentPath": "00", "InitMasterFtpAccount": "true"}}'
fi

#!/bin/sh

LOGICAL_ID=`atomia service list --account 100000 | jgrep "name=CsBase" -s logical_id`

# Create a website service if one does not exist
WEBSITE=`atomia service list --account 100000 --parent "$LOGICAL_ID" | jgrep  "name=CsLinuxWebsite" -s properties |  grep -o "atomia-nagios-test.net" | head -n1`

if [ "$WEBSITE" != "atomia-nagios-test.net" ]
then
        echo "Adding website to CsBase <$LOGICAL_ID>"
        atomia service add --account 100000 --parent "$LOGICAL_ID" --servicedata '{ "name" : "CsLinuxWebsite", "properties" : {"Hostname" : "atomia-nagios-test.net", "DomainPrefix" : "null", "DnsZone" : "atomia-nagios-test.net", "InfoEmailPassword" : "abcd1234"}}'
fi
