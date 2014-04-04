#!/bin/sh

PACKAGE=`atomia package list --account 100000  | grep current | head -n1 | sed 's/\"//g' | sed 's/://' | sed 's/,//' | tr -d ' '`

# Does not contain any packages
if [ "$PACKAGE" != "current_request_id" ]
then
        atomia package add --account 100000 --packagedata '{"package_name": "BasePackage", "package_arguments" : { "ADPassword": "7DSmHPUL", "FtpPassword": "Abc123", "PosixUid": "100000", "RootFolderParentPath": "00", "InitMasterFtpAccount": "true"}}'
fi
