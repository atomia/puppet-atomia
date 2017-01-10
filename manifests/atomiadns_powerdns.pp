## Atomia DNS PowerDNS agent

### Deploys and configures a nameserver running the Atomia DNS PowerDNS agent.

### Variable documentation
#### db_hostname: The hostname of the PowerDNS database.
#### db_username: The username for the PowerDNS database.
#### db_password: The password for the PowerDNS database.


### Validations
##### db_hostname(advanced): %hostname
##### db_username(advanced): %username
##### db_password(advanced): %password


class atomia::atomiadns_powerdns (
  $db_hostname  = '127.0.0.1',
  $db_username  = 'powerdns',
  $db_password  = '',
) {
  $atomia_dns_url          = hiera('atomia::atomiadns::atomia_dns_url','http://$fqdn/atomiadns')
  $agent_user              = hiera('atomia::atomiadns::agent_user','atomiadns')
  $agent_password          = hiera('atomia::atomiadns::agent_password','')
  $ns_group                = hiera('atomia::atomiadns::ns_group','default')
  $atomia_dns_extra_config = hiera('atomia::atomiadns::atomia_dns_extra_config','')

  if !in_atomia_role('atomiadns') and !defined(File['/etc/atomiadns.conf']) {
    file { '/etc/atomiadns.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('atomia/atomiadns_powerdns/atomiadns.conf.erb'),
      notify  => [ Service['atomiadns-powerdnssync'] ],
    }
  }

  if $::lsbdistrelease == '14.04' or $::lsbdistrelease == '16.04' {
    $pdns_package = 'pdns-server'

    package { 'pdns-backend-mysql':
      ensure  => present,
      require => [ Package[$pdns_package] ]
    }
  } else {
    $pdns_package = 'pdns-static'
  }

  if $::lsbdistrelease == '16.04' {
    package { 'libdbi-perl':
      ensure => present
    }

    file { '/etc/apt/sources.list.d/pdns.list':
      ensure  => present,
      content => 'deb [arch=amd64] http://repo.powerdns.com/ubuntu xenial-auth-40 main'
    } ->
    file { '/etc/apt/preferences.d/pdns':
      ensure  => present,
      content => 'Package: pdns-*
  Pin: origin repo.powerdns.com
  Pin-Priority: 600
  ',
      notify  => Exec['powerdns-pubkey']
    } ->
    exec {'powerdns-pubkey':
      command => '/usr/bin/curl https://repo.powerdns.com/FD380FBB-pub.asc | /usr/bin/sudo /usr/bin/apt-key add -',
      refreshonly => true,
      notify  => Exec['apt-update-pdns']
    } ->
    exec {'apt-update-pdns':
      command => '/usr/bin/apt-get update',
      refreshonly => true,
    } ->
    package { $pdns_package:
      ensure  => present
    }
  } else {
    package { $pdns_package:
      ensure  => present
    }
  }

  service { 'pdns':
    ensure  => running,
    require => [ Package[$pdns_package] ]
  }

  package { 'atomiadns-powerdns-database':
    require => [ File['/etc/atomiadns.conf'], Package[$pdns_package] ],
    notify  => [ Service['pdns'] ]
  }

  package { 'atomiadns-powerdnssync':
    ensure  => present,
    require => [ Package['atomiadns-powerdns-database'] ]
  }

  if $::operatingsystem == 'Ubuntu' {
    package { 'dnsutils': ensure => present }
  } else {
    package { 'bind-utils': ensure => present }
  }

  service { 'atomiadns-powerdnssync':
    ensure  => running,
    name    => atomiadns-powerdnssync,
    pattern => '.*powerdnssync.*',
    require => [ Package['atomiadns-powerdns-database'], Package['atomiadns-powerdnssync'] ],
  }

  if !in_atomia_role('atomiadns') {
    exec { 'add-server':
      command => "/usr/bin/atomiapowerdnssync add_server \"${ns_group}\" && service atomiadns-powerdnssync stop && service atomiadns-powerdnssync start && /usr/bin/atomiapowerdnssync full_reload_online",
      require => [ Package['atomiadns-powerdnssync'] ],
      unless  => ['/usr/bin/atomiapowerdnssync get_server'],
    }
  } else {
    exec { 'add-server':
      command => "/usr/bin/atomiapowerdnssync add_server \"${ns_group}\" && service atomiadns-powerdnssync stop && service atomiadns-powerdnssync start && /usr/bin/atomiapowerdnssync full_reload_online",
      require => [ Package['atomiadns-powerdnssync'], Exec['add_nameserver_group'] ],
      unless  => ['/usr/bin/atomiapowerdnssync get_server'],
    }
  }
}
