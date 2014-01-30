#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
	echo "usage: $0 atomia_ad_base_dn atomia_ad_ldap_uris atomia_ad_bind_user atomia_ad_bind_password"
	exit 1
else
	atomia_ad_base_dn="$1"
	atomia_ad_ldap_uris="$2"
	atomia_ad_bind_user="$3"
	atomia_ad_bind_password="$4"
fi

cat <<EOF
base $atomia_ad_base_dn
uri $atomia_ad_ldap_uris
ldap_version 3
binddn cn=$atomia_ad_bind_user,$atomia_ad_base_dn
bindpw $atomia_ad_bind_password
scope group sub
scope hosts sub
ssl no

filter passwd (&(objectClass=user)(!(objectClass=computer))(uidNumber=*)(unixHomeDirectory=*))
map    passwd homeDirectory    unixHomeDirectory
filter shadow (&(objectClass=user)(!(objectClass=computer))(uidNumber=*)(unixHomeDirectory=*))
map    shadow shadowLastChange pwdLastSet
filter group  (objectClass=group)
#map    group  uniqueMember     member

uid nslcd
#gid ldap
tls_cacertdir /etc/openldap/cacerts
EOF
