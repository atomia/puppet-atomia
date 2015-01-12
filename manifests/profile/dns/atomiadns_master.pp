# == Class: atomia::profile::atomiadns_master
#
# The atomiadns_master profile installs the required packages and configures
# an atomiadns server
#
# === Parameters
#
# Required:
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
#
# === Authors
#
# Stefan Mortensen <stefan@atomia.com>
#


class atomia::profile::dns::atomiadns_master (
  $certificate     =  hiera('atomia::profile::dns::certificate',false) ,
  $nameserver_group = hiera('atomia::profile::dns::nameserver_group','default'),
  ){

  # Install packages
  package { 'atomiadns-masterserver':
    ensure => present,
  }

  if !defined(Package['atomiadns-client']) {
    package { 'atomiadns-client':
      ensure => present,
    }
  }

  # File management
  if $certificate != false {
    file { '/etc/atomiadns-mastercert.pem':
      owner   => root,
      group   => root,
      mode    => '0440',
      content => $certificate
    }
  }

  # Execs
  exec { 'add_nameserver_group':
    require => [Package['atomiadns-masterserver'], Package['atomiadns-client']],
    unless  => "/usr/bin/sudo -u postgres psql zonedata -tA -c \
    \"SELECT name FROM nameserver_group WHERE name = '${nameserver_group}'\"|\
    grep '^${nameserver_group}\$'",
    command => "/usr/bin/sudo -u postgres psql zonedata -c \
    \"INSERT INTO nameserver_group (name) VALUES ('${nameserver_group}')\"",
  }

  /* TODO stuff

  if !defined(Class['atomia::apache_password_protect']) {
  class { 'atomia::apache_password_protect':
  username => $agent_user,
  password => $agent_password
}
}
  */


}
