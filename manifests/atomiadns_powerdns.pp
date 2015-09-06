#
# == Class: atomia::atomiadns_powerdns
#
# Manifest to install/configure a powerdns nameserver 
#
# [password]
# Define a password for accessing atomiadns
# (required) 
#
# [agent_user]
# Defines the username for accessing atomiadns
# (optional) Default: atomiadns
#
# [atomia_dns_url]
# Url of atomiadns endpoint
# (required)
#
# [atomia_dns_ns_group]
# Nameserver group to subscribe to
# (optional) Default: default
#
# [ssl_enabled]
# Defines if ssl is enabled
# (optional) Defaults to false
#
#
# === Examples
#
# class {'atomia::atomiadns_powerdns':
#        agent_password   => 'abc123',
#        atomia_dns_url   => 'http://127.0.0.1/atomiadns',
#}

class atomia::atomiadns_powerdns (
  # If ssl should be enabled or not
  $ssl_enabled = 0,
  $agent_user = "atomiadns",
  $agent_password,
  $atomia_dns_url,
  $atomia_dns_ns_group = "default") {
  package { atomiadns-powerdns-database: ensure => present }

  package { atomiadns-powerdnssync: ensure => present }

  if $lsbdistrelease == "14.04" { 
	package { pdns-server:
    ensure  => present,
    require => [Service["atomiadns-powerdnssync"]]}
	package { pdns-backend-mysql:
	ensure => present,
	require => [Package[pdns-server]]}
  } else {
  	package { pdns-static:
    ensure  => present,
    require => [Service["atomiadns-powerdnssync"]]}
  }

  if $operatingsystem == "Ubuntu" {
    package { dnsutils: ensure => present }
  } else {
    package { bind-utils: ensure => present }
  }

  service { atomiadns-powerdnssync:
    name      => atomiadns-powerdnssync,
    ensure    => running,
    pattern   => ".*powerdnssync.*",
    require   => [
      Package["atomiadns-powerdns-database"],
      Package["atomiadns-powerdnssync"],
      File["/etc/atomiadns.conf.powerdnssync"]],
    #subscribe => [File["/etc/atomiadns.conf.powerdnssync"]],
  }

  if $ssl_enabled == '1' {
    file { "/etc/atomiadns-mastercert.pem":
      owner  => root,
      group  => root,
      mode   => 440,
      source => "puppet:///modules/atomia/atomiadns_powerdns/atomiadns_cert"
    }

  }



  file { "/etc/atomiadns.conf.powerdnssync":
    owner   => root,
    group   => root,
    mode    => 444,
    content => template("atomia/atomiadns_powerdns/atomiadns.conf.powerdnssync.erb"),
    require => [Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"]],
    #notify  => Exec["atomiadns_config_sync"],
  }

  if !defined(File["/usr/bin/atomiadns_powerdns_config_sync"]) {
    file { "/usr/bin/atomiadns_powerdns_config_sync":
      owner   => root,
      group   => root,
      mode    => 500,
      source  => "puppet:///modules/atomia/atomiadns_powerdns/atomiadns_config_sync",
      require => [Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"]],
    }
  }

  exec { "atomiadns_powerdns_config_sync":
    require     => [File["/usr/bin/atomiadns_powerdns_config_sync"],File["/etc/atomiadns.conf.powerdnssync"], Package['atomiadns-powerdnssync']],
    command     => "/usr/bin/atomiadns_powerdns_config_sync $atomia_dns_ns_group",
  }  
  ->
  exec { "add-server":
    command => "/usr/bin/atomiapowerdnssync add_server $atomia_dns_ns_group && /etc/init.d/atomiadns-powerdnssync stop && /etc/init.d/atomiadns-powerdnssync start && /usr/bin/atomiapowerdnssync full_reload_online",
    #require => [Package["atomiadns-powerdnssync"],Exec['atomiadns_powerdns_config_sync'],Service['atomiadns-powerdnssync']],
    unless  => ["/usr/bin/atomiapowerdnssync get_server"],
  }
}

