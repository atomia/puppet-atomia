class atomia::linux_base {

    package { sudo: ensure => present }

    include '::ntp'

    $internal_dns = hiera('atomia::internaldns::ip_address')

    if $internal_dns {
      class { 'resolv_conf':
        nameservers => ["${internal_dns}"],
      }
    }    
}
