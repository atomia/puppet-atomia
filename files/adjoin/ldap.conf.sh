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
scope sub
bind_policy soft
ssl no

nss_base_passwd $atomia_ad_base_dn
nss_base_shadow $atomia_ad_base_dn
nss_base_group $atomia_ad_base_dn

nss_map_objectclass posixAccount user
nss_map_objectclass shadowAccount user

nss_map_attribute homeDirectory unixHomeDirectory

nss_map_objectclass posixGroup Group
nss_map_attribute cn sAMAccountName

pam_filter objectclass=user
pam_password ad
EOF

