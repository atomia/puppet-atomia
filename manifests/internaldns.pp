## Atomia Internal DNS

### Deploys and configures a dns server which are used for resolving internal dns records

### Variable documentation
#### zone_name: The name of the zone where all servers will be placed (for example atomia.internal)

### Validations
##### zone_name: .*


class atomia::internaldns (
	$zone_name     		= ""
){

class { 'bind': }

bind::zone {"$zone_name":
  zone_contact => "contact.${$zone_name}",
  zone_ns      => ["ns0.${$zone_name}"],
  zone_serial  => '2012112901',
  zone_ttl     => '604800',
  zone_origin  => "${$zone_name}",
}


# Set ip correctly when on ec2
if $ec2_public_ipv4 {
  $public_ip = $ec2_public_ipv4
} else {
  $public_ip = $ipaddress_eth0
}

@@bind::a { 'Hosts in zone':
  ensure    => 'present',
  zone      => "${$zone_name}",
  ptr       => false,
  hash_data => {
    'ns0' => { owner => "${public_ip}" },
    'intdns' => { owner => "${public_ip}" },
  },
}

Bind::A <<| |>>

}
