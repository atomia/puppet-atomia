## Atomia Internal DNS

### Deploys and configures a dns server which are used for resolving internal dns records

### Variable documentation
#### zone_name: The name of the zone where all servers will be placed (for example atomia.internal)
#### ip_address: The private ip address of the server

### Validations
##### zone_name: .*
##### ip_address(advanced): .*

class atomia::internaldns (
  $zone_name         = '',
  $ip_address        = $ipaddress
){


  class { 'bind':
    default_view => {
      'recursion' => 'yes',
    },
    config       => {
      'allow-query' => '{ any; }',
    }
  }

  bind::zone {$zone_name:
    zone_contact => "contact.${zone_name}",
    zone_ns      => ["ns0.${zone_name}"],
    zone_serial  => '2012112901',
    zone_ttl     => '604800',
    zone_origin  => $zone_name,
  }

  $ad_domain = hiera('atomia::active_directory::domain_name', '')
  if($ad_domain != '') {
    bind::zone {$ad_domain:
      zone_type       => 'forward',
      zone_ttl        => '604800',
      zone_forwarders => '52.30.144.80'
    }
  }

  # Set ip correctly when on ec2
  if $::ec2_public_ipv4 {
    $public_ip = $::ec2_public_ipv4
  } elsif $::ipaddress_eth0 {
    $public_ip = $::ipaddress_eth0
  }
  else {
    $public_ip = $::ipaddress
  }

  @@bind::a { 'Hosts in zone':
    ensure    => 'present',
    zone      => $zone_name,
    ptr       => false,
    hash_data => {
      'ns0'    => {
        owner => $public_ip
      },
      'intdns' => {
      owner => $public_ip
      },
    },
  }

  Bind::A <<| |>>

  exec { 'restart_bind':
    command     => '/etc/init.d/bind9 restart',
    refreshonly => true,
  }

}
