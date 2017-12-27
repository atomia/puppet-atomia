#!/bin/bash
###############################################################
#Project: 	    Atomia Keepalived check script
#Date: 		    2017-12-07
#Last update:   2017-12-11
#Author: 	    NVitanovic
###############################################################
#This script is used by keepalived to check if the service is
#working properly
###############################################################
##  VARIABLES ##
###############################################################
TYPE=0              #0 - nothing (just service), 1 - ips, 2 - ports
TIMEOUT=1           #timeout for checking if the port is open in secs
CHK_SERVICE="$1"    #the service which status is checked -> "haproxy" probably
MAX_FAIL_COUNT=0    #max number of fails to ignore
CHK_HOSTS=()        #(192.168.254.100)
CHK_PORTS=()        #(80)
shift               #shift needed because first parameter (service name is needed) and needs to be skipped before parsing other parameters
###############################################################

###############################################################
##  PARMETERS PARSE ##
###############################################################
#parse the input data and add to the appropirate array
N=$#                # number of arguments

#going trough all parameters and checking the type 
for ((I=0;I<N;I++)); do
 #echo $I $1
 #checks the type of the current argument in order to determine to which array it should add the value
 case $1 in
  ("--ips")
   TYPE=1
  ;;
  ("--ports")
   TYPE=2
  ;;
  ("--max-fail")
   #move to the max fail count if detected and apply it
   shift
   #check if the argument is a number and set the value if it is
   if [ "$1" -eq "$1" ] 2>/dev/null
   then
    MAX_FAIL_COUNT=$1
   fi
  ;;
  ("--timeout")
   #move to the max fail count if detected and apply it
   shift
   #check if the argument is a number and set the value if it is
   if [ "$1" -eq "$1" ] 2>/dev/null
   then
    TIMEOUT=$1
   fi
  ;;
  (*) 
   #if no special argument is specified then the current argument is added to the appropriate array based on type
   #adding value to the appropirate array
   if [ $TYPE -eq 1 ]
   then
    CHK_HOSTS+=($1);
   else
    CHK_PORTS+=($1);
   fi
  ;;
 esac
 shift
done

#if max fail count not supplied persume 0 is max number of errors
if [ -z "$MAX_FAIL_COUNT" ]
then
 MAX_FAIL_COUNT=0
fi
###############################################################
##  LOGIC ##
###############################################################
#varible shows how many errors it detects (current number of errors)
FAIL_COUNT=0

#current date
DATE=`date '+%Y-%m-%d %H:%M:%S'`

#1. get Haproxy status check service
/etc/init.d/$CHK_SERVICE status > /dev/null
STATUS=$?

if [ "$STATUS" != 0 ]
then
 logger "[$DATE] ERROR: $CHK_SERVICE service status failed with: $STATUS" #>> /tmp/script.log
 FAIL_COUNT=$((FAIL_COUNT + 1))
fi

#2. check if ips  accept incomming connections a.k.a listen on list of specified ports
for CURRENT_HOST in ${CHK_HOSTS[@]}; do
 #check for timeout or drop
 for CURRENT_PORT in ${CHK_PORTS[@]}; do
  nc -w $TIMEOUT -z $CURRENT_HOST $CURRENT_PORT > /dev/null
  if [ "$?" != 0 ]
  then
   logger "[$DATE] ERROR: Host not accepting connections or not online: $CURRENT_HOST:$CURRENT_PORT" #>> /tmp/script.log
   FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
 done 
done

#check if number of errors is greater than max number of errors
#if the number is less than the max then no IP change
if [ $MAX_FAIL_COUNT -ge $FAIL_COUNT ]
then
    exit 0
fi

#display script status and return code
#if return is 0 fails then VRRP will not switch the ip
#echo "[$DATE] Script ran with: $FAIL_COUNT" >> /tmp/script.log
exit $FAIL_COUNT