# == Class: atomia::profile::general::atomia_repository
#
# Adds the required Atomia repositories
#
# === Parameters
#
# === Authors
#
# Stefan Mortensen <stefan@atomia.com>
#
class atomia::profile::general::atomia_repository(){

  $repo = "ubuntu-${::lsbdistcodename} ${::lsbdistcodename} main"

  file { '/etc/apt/sources.list.d/atomia.list':
    owner   => root,
    group   => root,
    mode    => '0440',
    content => "deb http://apt.atomia.com/${repo}",
  }

  file { '/etc/apt/ATOMIA-GPG-KEY.pub':
    owner  => root,
    group  => root,
    mode   => '0440',
    source => 'puppet:///modules/atomia/repository/ATOMIA-GPG-KEY.pub',
  }

  file { '/etc/apt/apt.conf.d/80atomiaupdate':
    owner  => root,
    group  => root,
    mode   => '0440',
    source => 'puppet:///modules/atomia/repository/80atomiaupdate',
  }

  exec { 'add keys':
    command     => '/usr/bin/apt-key add /etc/apt/ATOMIA-GPG-KEY.pub',
    onlyif      => ['/usr/bin/test -f /etc/apt/ATOMIA-GPG-KEY.pub'],
    subscribe   => File['/etc/apt/ATOMIA-GPG-KEY.pub'],
    refreshonly => true
  }

  exec { 'apt-update':
    command => '/usr/bin/apt-get update',
    require => File['/etc/apt/apt.conf.d/80atomiaupdate',
    '/etc/apt/ATOMIA-GPG-KEY.pub', '/etc/apt/sources.list.d/atomia.list']
  }

  Exec['apt-update'] -> Package <| |>
}
