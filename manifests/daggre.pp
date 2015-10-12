class atomia::daggre (
	$global_auth_token, 
	$ip_addr = $ipaddress, 
	$content_share_nfs_location = '', 
	$config_share_nfs_location = '', 
	$use_nfs3 = true 
	) {
  
  include atomia::mongodb

  class { 'apt': }
  
  if $operatingsystem == "Ubuntu" {
    apt::ppa { 'ppa:chris-lea/node.js': }

    package { nodejs:
      ensure  => latest,
      require => [Apt::Ppa['ppa:chris-lea/node.js'], Exec['apt-get-update'], Package['python-software-properties']]
    }

    exec { "apt-get-update": command => "/usr/bin/apt-get update" }
  } else {
    package { nodejs: ensure => present, }
  }

  package { python-software-properties:
    ensure => present,
  }  
  
  package { "daggre":
    ensure  => present,
    require => [Package["mongodb-10gen"], Package["nodejs"]],
  }

  package { "atomia-daggre-reporters-disk":
    ensure  => present,
    require => Package["daggre"]
  }

  package { "atomia-daggre-reporters-weblog":
    ensure  => present,
    require => Package["daggre"]
  }

  file { "/etc/default/daggre":
    owner   => root,
    group   => root,
    mode    => 440,
    content => template("atomia/daggre/settings.cfg.erb"),
    require => Package["daggre"],
  }

  file { "/etc/daggre_submit.conf":
    owner   => root,
    group   => root,
    mode    => 440,
    content => template("atomia/daggre/daggre_submit.conf.erb"),
    require => Package["atomia-daggre-reporters-disk", "atomia-daggre-reporters-weblog"],
  }

  service { "daggre":
    name      => daggre,
    enable    => true,
    ensure    => running,
    pattern   => ".*/usr/bin/daggre.*",
    require   => [Package["daggre"], File["/etc/default/daggre"]],
    subscribe => File["/etc/default/daggre"],
  }

  if $content_share_nfs_location != '' {
    atomia::nfsmount { 'mount_content':
      use_nfs3 => $use_nfs3,
      mount_point => '/storage/content',
      nfs_location => $content_share_nfs_location
    }
  }
  
  if $config_share_nfs_location != '' {
    atomia::nfsmount { 'mount_config':
      use_nfs3 => $use_nfs3,
      mount_point => '/storage/configuration',
      nfs_location => $config_share_nfs_location
    }
  }

}
