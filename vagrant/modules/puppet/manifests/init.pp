# == Class: puppet
# This class install and manages Puppet and requirements
#
# === Parameters
#
# === Actions
#
# === Requires

class puppet()
{
  package {'puppet':
    ensure => latest,
  }

  package {'git':
    ensure  => latest,
  }

  package { 'apache2-utils':
    ensure => latest
  }

  package { 'rubygems-integration':
    ensure => latest,
  }

  exec { 'install-rake':
  command => '/usr/bin/gem install rake',
  require => Package['rubygems-integration'],
  }

  exec { 'install-bundler':
    command => '/usr/bin/gem install bundler',
    require => Package['rubygems-integration'],
  }

  exec { 'run-bundle-install':
    command => '/usr/local/bin/bundle install',
    cwd     => '/vagrant',
    require => Exec['install-bundler'],
  }

  exec { 'install-watchr':
    command => '/usr/bin/gem install watchr',
    require => Package['rubygems-integration'],
    }

  # Set up specs
  file { '/vagrant/spec/fixtures/modules/atomia':
    ensure  => directory
  }

  exec { 'create-module-symlinks':
    command => '/bin/bash -c \'for i in files lib manifests templates; \
    do ln -s ../../../../$i $i; done\'',
    cwd     => '/vagrant/spec/fixtures/modules/atomia',
    require => File['/vagrant/spec/fixtures/modules/atomia'],
    creates => '/vagrant/spec/fixtures/modules/atomia/manifests'
    }

  exec { 'apt-update':
      command => '/usr/bin/apt-get update'
    }

  Exec['apt-update'] -> Package <| |>

}
