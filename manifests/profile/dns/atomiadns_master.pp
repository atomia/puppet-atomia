# == Class: atomia::profile::dns::atomiadns_master
#
# The atomiadns_master profile installs the required packages and configures
# an atomiadns server
#
# === Parameters
#
# Required:
#
#  [*$atomiadns_password*]
#   (hiera: atomia::profile::dns::atomiadns_password)
#   The unique password for http auth to the AtomiaDNS api
#
#  [*$nameservers*]
#   (hiera: atomia::profile::dns::nameservers)
#   Array of hostnames for all dns servers
#
# Optional:
#  [*$certificate*]
#   (hiera: atomia::profile::dns:certificate)
#   Pem certificate to use if SSL should be supported if not defined SSL
#   will not be used.
#
#  [*$nameserver_group*]
#   (hiera: atomia::profile::dns::nameserver_group)
#   The name server group to create for AtomiaDNS defaults to 'default'
#
#  [*$atomiadns_url*]
#   (hiera: atomia::profile::dns::atomiadns_url)
#   The url to use for the AtomaDNS api endpoint
#   defaults to 'http://localhost/atomiadns'
#
#  [*$atomiadns_user*]
#   (hiera: atomia::profile::dns::atomiadns_user)
#   The username for http auth to the AtomiaDNS api defaults to 'atomiadns'
#
#  [*$dns_zones*]
#   (hiera: atomia::profile::dns::atomiadns_master::dns_zones)
#   Array of dns zones to add
#
#  [*$registry*]
#   (hiera: atomia::profile::dns::registry)
#   The registry address
#   REQUIRED if dns_zones are set
#   Example: registry.atomia.com
#
# === Authors
#
# Stefan Mortensen <stefan@atomia.com>
#


class atomia::profile::dns::atomiadns_master (
  $certificate =
  hiera('atomia::profile::dns::certificate',false),

  $nameserver_group =
  hiera('atomia::profile::dns::nameserver_group','default'),

  $atomiadns_url =
  hiera('atomia::profile::dns::atomiadns_url','http://localhost/atomiadns'),

  $atomiadns_user =
  hiera('atomia::profile::dns::atomiadns_user','atomiadns'),

  $atomiadns_password =
  hiera('atomia::profile::dns::atomiadns_password'),

  $nameservers =
  hiera('atomia::profile::dns::nameservers'),

  $registry =
  hiera('atomia::profile::dns::registry',''),

  $dns_zones = false,

  ){


  ##### Install packages
  package { 'atomiadns-masterserver':
    ensure => present,
  }

  if !defined(Package['atomiadns-client']) {
    package { 'atomiadns-client':
      ensure  => present
    }
  }

  #### File management
  if $certificate != false {
    file { '/etc/atomiadns-mastercert.pem':
      owner   => root,
      group   => root,
      mode    => '0440',
      content => $certificate
    }
  }

  file { '/etc/atomiadns.conf.master':
    owner   => root,
    group   => root,
    mode    => '0444',
    content => template('atomia/atomiadns/atomiadns.erb'),
    require => Package['atomiadns-masterserver'],
  }

  file { '/usr/bin/atomiadns_config_sync':
    owner   => root,
    group   => root,
    mode    => '0500',
    source  => 'puppet:///modules/atomia/atomiadns/atomiadns_config_sync',
    require => [Package['atomiadns-masterserver']],
  }

  #### Execs

  # Add a new nameserver group to AtomiaDNS
  exec { 'add_nameserver_group':
    require => [Package['atomiadns-masterserver'], Package['atomiadns-client']],
    unless  => "/usr/bin/sudo -u postgres psql zonedata -tA -c \
    \"SELECT name FROM nameserver_group WHERE name = '${nameserver_group}'\"|\
    grep '^${nameserver_group}\$'",
    command => "/usr/bin/sudo -u postgres psql zonedata -c \
    \"INSERT INTO nameserver_group (name) VALUES ('${nameserver_group}')\"",
  }

  # Sync atomiadns configuration file
  exec { 'atomiadns_config_sync':
    require => [
      File['/usr/bin/atomiadns_config_sync'],
      File['/etc/atomiadns.conf.master']
    ],
    command => "/usr/bin/atomiadns_config_sync ${nameserver_group}",
    unless  => '/bin/grep  soap_uri /etc/atomiadns.conf',
    notify  => Service['apache2'],
  }

  # Add zones if specified
  if $dns_zones != false {

      file { '/usr/share/doc/atomiadns-masterserver/zones_to_add.txt':
        owner   => root,
        group   => root,
        mode    => '0500',
        content => join($dns_zones,'\n'),
        require => [
          Package['atomiadns-masterserver'],
          Package['atomiadns-client']
        ],
        notify  => Exec['remove_lock_file'],
      }

    exec { 'remove_lock_file':
      command     =>
      '/bin/rm -f /usr/share/doc/atomiadns-masterserver/sync_zones_done*.txt',
      refreshonly => true,
    }

    file { '/usr/share/doc/atomiadns-masterserver/add_zones.sh':
      owner   => root,
      group   => root,
      mode    => '0500',
      source  => 'puppet:///modules/atomia/atomiadns/add_zones.sh',
      require => [
        Package['atomiadns-masterserver'],
        Package['atomiadns-client']
      ],
    }

    $first_nameserver = $nameservers[0]
    $nameservers_joined = join($nameservers,',')
    $ns_arr_string = "\"[${nameservers_joined}]\""

    exec { 'atomiadns_add_zones':
      require => [
        File['/usr/share/doc/atomiadns-masterserver/zones_to_add.txt'],
        File['/usr/share/doc/atomiadns-masterserver/add_zones.sh'],
        Package['atomiadns-client'],
        Exec['atomiadns_config_sync'],
        Augeas['include_confd']
      ],
      command => "/bin/sh /usr/share/doc/atomiadns-masterserver/add_zones.sh\
    ${nameserver_group} ${first_nameserver} ${ns_arr_string} ${registry}",
      unless  => '/usr/bin/test -f \
      /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt',
    }
  }

  augeas {'include_confd':
    changes => [
    'set /files/etc/apache2/apache2.conf/directive[last() + 1] IncludeOptional',
    'set /files/etc/apache2/apache2.conf/directive[last()]/arg conf.d/*',
    ],
    onlyif  =>
      "match /files/etc/apache2/apache2.conf/directive/arg[.='conf.d/'] \
      size == 0",
    require => Package['atomiadns-masterserver'],
    notify  => Service['apache2'],
  }

  #### Services

  service { 'apache2':
    ensure => running,
    name   => 'apache2',
    enable => true,
  }

}
