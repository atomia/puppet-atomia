#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "usage: $0 account url user pass"
        exit 1
fi

ACCOUNT=$1
URL=$2
USER=$3
PASSWORD=$4
AUTH=`echo -n "$USER:$PASSWORD" | base64`
LAST_DIGITS=`echo -n $ACCOUNT | awk '{print substr($0,5,2)}' | tr -d '\n'`

# Test connection to the api endpoint
RESULT=`curl -m 3 -s -i $URL | grep HTTP | wc -l`
if [ $RESULT -eq 0 ]; then
        echo "CRITICAL: api endpoint $URL is not reachable"
        exit 2
fi

# Test getting the root folder for account
RESULT=`curl -m 3 -s -X GET -i -H "Authorization: Basic $AUTH" $URL/rootfolder/%2F$LAST_DIGITS%2F$ACCOUNT | grep "200 OK" | wc -l`
if [ $RESULT -eq 0 ]; then
        echo "CRITICAL: could not get root folder for account $ACCOUNT"
        exit 2
fi

# Check if testfolder exists
RESULT=`curl -m 3 -s -X GET -i -H "Authorization: Basic $AUTH" $URL/folder/%2F$LAST_DIGITS%2F$ACCOUNT%2Fnagiostestfolder | grep "200 OK" | wc -l`
if [ $RESULT -eq 1 ]; then
        # Folder exist we should delete it
        RESULT=`curl -m 3 -s -X DELETE -i -H "Authorization: Basic $AUTH" $URL/folder/%2F$LAST_DIGITS%2F$ACCOUNT%2Fnagiostestfolder | grep "200 OK" | wc -l`
        if [ $RESULT -eq 0 ]; then
                echo "CRITICAL: test folder exist but could not be deleted"
                exit 2
        fi
fi

RESULT=`curl -m3 -s -X POST -d '{"children":[],"name" : "nagiostestfolder", "permissions" : "710", "folderpath" : "/'$LAST_DIGITS'/'$ACCOUNT'", "owner" : '$ACCOUNT', "group" : 33}' -i -H "Authorization: Basic $AUTH" -H "Content-Type: application/json" -H "Accept: application/json" $URL/folder | grep "200 OK" | wc -l`
if [ $RESULT -eq 0 ]; then
        echo "CRITICAL: could not create test folder for account $ACCOUNT"
        exit 2
fi

# Test creating a file
RESULT=`curl -m3 -s -X POST -d '{"name" : "nagios-test.txt", "permissions" : 710, "folderpath" : "/'$LAST_DIGITS'/'$ACCOUNT'/nagiostestfolder", "owner" : '$ACCOUNT', "group" : 33 }' -i -H "Authorization: Basic $AUTH" -H "Content-Type: application/json" $URL/file | grep "200 OK" | wc -l`

if [ $RESULT -eq 0 ]; then
        echo "CRITICAL: could not create test file for account $ACCOUNT"
        exit 2
fi

echo "OK: All checks executed succesfully"
exit 0
