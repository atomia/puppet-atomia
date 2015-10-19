#!/bin/bash
# Atomia yaml conf file tuner
#
# Author: Branislav Vukelic <branislav@atomia.com>
#
#
clear

# Define some colors for readability
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32m"

# Declare variables 
FILES=/etc/puppet/hieradata/

# install subversion
apt-get install -y subversion

# Extracting network info from puppetmaster
# Get netstat information
[[ -f /tmp/netstat.tmp ]] && rm -f /tmp/netstat.tmp
/bin/netstat -nar | grep eth0 > /tmp/netstat.tmp
sed -i '/169.254.0.0/d' /tmp/netstat.tmp

# NS - Get NS addresses 
[[ -f /tmp/eth0.ns.tmp ]] && rm -f /tmp/eth0.ns.tmp
cat /etc/resolv.conf  | grep -v '^#' | grep nameserver | awk '{print $2}' | tr '\n' ' ' > /tmp/eth0.ns.tmp

# PUBLIC - Get the current IP
[[ -f /tmp/eth0.ip.tmp ]] && rm -f /tmp/eth0.ip.tmp
/sbin/ifconfig eth0 | grep "inet addr" | sed 's/.* addr://;s/[ \t]* .*//' > /tmp/eth0.ip.tmp

# NETWORK - Get the network IP
[[ -f /tmp/eth0.network.tmp ]] && rm -f /tmp/eth0.network.tmp
cp /tmp/netstat.tmp /tmp/eth0.network.tmp
sed -i '/UG/d;s/[ \t]* .*//' /tmp/eth0.network.tmp

# GATEWAY - Get the gateway IP
[[ -f /tmp/eth0.gateway.tmp ]] && rm -f /tmp/eth0.gateway.tmp
cp /tmp/netstat.tmp /tmp/eth0.gateway.tmp
sed -i '/[1-9]* .* U .*/d;s/0.0.0.0[ \t]*//;s/[ \t]* .*//' /tmp/eth0.gateway.tmp

# NETMASK - Get the network netmask
[[ -f /tmp/eth0.netmask.tmp ]] && rm -f /tmp/eth0.netmask.tmp
/sbin/ifconfig eth0 | grep Mask | sed 's/.* Mask://' > /tmp/eth0.netmask.tmp

# Assign variables from temp files
NAMESERVERS=`cat /tmp/eth0.ns.tmp`
PUPPET_ADDRESS=`cat /tmp/eth0.ip.tmp`
GATEWAY=`cat /tmp/eth0.gateway.tmp`
NETWORK=`cat /tmp/eth0.network.tmp`
NETMASK=`cat /tmp/eth0.netmask.tmp`

echo "ADDRESS is $PUPPET_ADDRESS"
echo "GATEWAY is $GATEWAY"
echo "NETWORK is $NETWORK"
echo "NETMASK is $NETMASK"
echo "NAMESERVERS are $NAMESERVERS"

# Function to populate conf.lan
populatelan ()
{
MANAGEMENTSUBNET=${NETWORK%.*}

sed -i "s/192.0.2/$MANAGEMENTSUBNET/g" /etc/puppet/hieradata/nodes/config.temp

[[ -f /etc/puppet/hieradata/nodes/config.lan ]] && rm -f /etc/puppet/hieradata/nodes/config.lan
while read -r line ; do
  [[ $line == * ]] && line+=",$NETWORK,$NETMASK,$GATEWAY,$NAMESERVERS"
  echo "$line" >> /etc/puppet/hieradata/nodes/config.lan
done < /etc/puppet/hieradata/nodes/config.temp
}

# Function to pull default config files from git
pullyaml ()
{
  svn checkout https://github.com/atomia/puppet-atomia/branches/stable/examples/hieradata /etc/puppet/hieradata
  rm -rf /etc/puppet/hieradata/.svn
}

# Function to add installuser
addinstalluser ()
{
sudo adduser installuser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "installuser:password" | sudo chpasswd
}

# Function to go trough all yaml files and populate data
populateyaml ()
{
MANAGEMENTSUBNET=${NETWORK%.*}

# Cycle trough all resources files
for f in `find /etc/puppet/hieradata/* -maxdepth 0 -type f`
do
  # Setup management network subnet
  sed -i "s/192.0.2/$MANAGEMENTSUBNET/g" $f
  # Setup public domain
  sed -i "s/yourdomain.com/$PUBLICDOMAIN/g" $f  
  # Generate random passwords
  RANDOMPASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w25 | head -n1`
  sed -i "s/SeriousPa55/$RANDOMPASS/g" $f
  RANDOMPASS2=`tr -cd '[:alnum:]' < /dev/urandom | fold -w25 | head -n1`
  sed -i "s/SeriousPa66/$RANDOMPASS2/g" $f
  echo -e "$f ->$COL_GREEN done ..."  $COL_RESET
done

# Copy domainreg service password to windows.yaml
  DREGPASS=`grep -r domainreg::service_password /etc/puppet/hieradata/domainreg.yaml | cut -d'"' -f2`
  #echo $DREGPASS
  sed -i "s/PassfromDREG/$DREGPASS/g" /etc/puppet/hieradata/windows.yaml
# Copy Master DNS password to atomiadns_ns.yaml 
  MDNSPASS=`grep -r atomiadns::agent_password /etc/puppet/hieradata/atomiadns.yaml | cut -d'"' -f2`
  #echo $MDNSPASS
  sed -i "s/PassfromMDNS/$MDNSPASS/g" /etc/puppet/hieradata/atomiadns_ns.yaml
# Print result of password generation  
  #grep -r password $FILES | cut -d':' -f4,6,7
}

# Interactive part
echo ""
echo "=========================================================="
echo -e $COL_GREEN "This is a helper script for Atomia platform puppetmaster" $COL_RESET
echo "=========================================================="

read -e -p "Enter Atomia platform public domain (eg. example.com): " PDOMAIN
PUBLICDOMAIN=${PDOMAIN}

echo "=========================================================="
read -e -p "Enter Public IP for APACHE cluster (eg. 203.0.113.2): " APACHE
echo "=========================================================="
APACHEIP=${APACHE}
echo -e "Apache\t IP:\t$COL_GREEN $APACHEIP $COL_RESET" >> IPLIST
cat IPLIST

echo "=========================================================="
read -e -p "Enter Public IP for IIS cluster (eg. 203.0.113.3): " IIS
echo "=========================================================="
IISIP=${IIS}
echo -e "IIS\t IP:\t$COL_RED $IISIP $COL_RESET" >> IPLIST
cat IPLIST

echo "=========================================================="
read -e -p "Enter Public IP for MAIL cluster (eg. 203.0.113.4): " MAIL
echo "=========================================================="
MAILIP=${MAIL}
echo -e "Mail\t IP:\t$COL_GREEN $MAILIP $COL_RESET" >> IPLIST
cat IPLIST

echo "=========================================================="
read -e -p "Enter Public IP for FTP cluster (eg. 203.0.113.4): " FTP
echo "=========================================================="
FTPIP=${FTP}
echo -e "FTP\t IP:\t$COL_RED $FTPIP $COL_RESET" >> IPLIST
cat IPLIST

rm -rf IPLIST

# Execution
pullyaml
if (( $? )); then
  echo -e $COL_RED "Retrieving template files from GIT failed... " $COL_RESET >&2
  exit 1
else
  echo -e $COL_GREEN "Template files retrieved !!! " $COL_RESET
fi

populatelan
if (( $? )); then
  echo -e $COL_RED "Management network template population failed..." $COL_RESET >&2
  exit 1
else
  echo -e $COL_GREEN "Template file populated !!!" $COL_RESET
fi

populateyaml
if (( $? )); then
  echo -e $COL_RED "Populate yaml templates failed..." $COL_RESET >&2
  exit 1
else
  echo -e $COL_GREEN "Yaml templates populated !!!" $COL_RESET
fi

service puppetmaster force-reload
if (( $? )); then
  echo -e $COL_RED "Puppetmaster couldnt be reloaded..." $COL_RESET >&2
  exit 1
else
  echo -e $COL_GREEN "Puppetmaster reloaded !!!" $COL_RESET
fi

addinstalluser
if (( $? )); then
  echo -e $COL_RED "Add installuser failed ..." $COL_RESET >&2
  exit 1
else
  echo -e $COL_GREEN "installuser added !!!" $COL_RESET
fi

exit 0