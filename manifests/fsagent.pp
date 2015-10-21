class atomia::fsagent (
  $username   = "fsagent",
  $password,
  $content_share_nfs_location,
  $skip_mount = 0,
  $fsagent_ip = $ipaddress,
  $use_ssl    = false,
  $create_storage_files = false,
  $allow_ssh_key = "") {
  package { python-software-properties: ensure => present }

  package { python: ensure => present }

  package { 'g++': ensure => present }

  package { make: ensure => present }

  package { procmail: ensure => present }

  class { 'apt': }

  if $operatingsystem == "Ubuntu" {
    apt::ppa { 'ppa:chris-lea/node.js': 
    require => Package["python-software-properties"], 
    }

    package { nodejs:
      ensure  => latest,
      require => [Apt::Ppa['ppa:chris-lea/node.js'], Exec['apt-get-update']]
    }

    exec { "apt-get-update": command => "/usr/bin/apt-get update" }
  } else {
    package { nodejs: ensure => present, }
  }

  package { atomia-fsagent: ensure => present }

  if ($skip_mount == 0) {
    atomia::nfsmount { 'mount_content':
      use_nfs3     => 1,
      mount_point  => '/storage/content',
      nfs_location => $content_share_nfs_location
    }
  }

  if !defined(File["/storage"]) {
    file { "/storage":
      ensure => directory,
    }
  }

  if !defined(File["/storage/content"]) {
    file { "/storage/content":
      ensure => directory,
      require => File["/storage"],
    }
  }

  file { "/storage/content/backup":
    ensure => "directory",
    owner  => root,
    group  => root,
    mode   => 710,
    require => File["/storage/content"],
  }

  file { "/etc/default/fsagent":
    owner   => root,
    group   => root,
    mode    => 440,
    content => template("atomia/fsagent/settings.cfg.erb"),
    require => [Package["atomia-fsagent"], File["/storage/content/backup"]],
  }

  file { "/storage/configuration":
    ensure => directory,
    mode   => 711,
    require => File["/storage"],
  }

  file { "/etc/cron.d/clearsessions":
    ensure  => file,
    content => "15 * * * * root lockfile -r0 /var/run/clearsession.lock && (find /storage/configuration/php_session_path -mtime +2 -exec rm -f '{}' '+'; rm -f /var/run/clearsession.lock) \n"
  }

  if $use_ssl {
    file { "/etc/default/fsagent-ssl":
      owner   => root,
      group   => root,
      mode    => 440,
      ensure  => present,
      content => template("atomia/fsagent/settings-ssl.cfg.erb"),
      require => [Package["atomia-fsagent"]],
    }

    file { "/etc/init.d/atomia-fsagent-ssl":
      owner   => root,
      group   => root,
      mode    => 755,
      ensure  => present,
      content => template("atomia/fsagent/atomia-fsagent-ssl.erb"),
      require => [Package["atomia-fsagent"], File["/etc/default/fsagent-ssl"]],
    }

  }

  service { atomia-fsagent:
    name      => atomia-fsagent,
    enable    => true,
    ensure    => running,
    hasstatus => false,
    pattern   => "/usr/bin/nodejs /usr/lib/atomia-fsagent/main.js",
    subscribe => [Package["atomia-fsagent"], File["/etc/default/fsagent"]],
  }

  if $use_ssl {
    service { atomia-fsagent-ssl:
      name      => atomia-fsagent-ssl,
      enable    => true,
      ensure    => running,
      subscribe => [Package["atomia-fsagent"], File["/etc/default/fsagent-ssl"]],
      require   => [Service["atomia-fsagent"], File["/etc/init.d/atomia-fsagent-ssl"]],
    }
  }

  if $create_storage_files {
    file { '/root/storage.tar.gz':
      ensure => file,
      source => "puppet:///modules/atomia/fsagent/storage.tar.gz",
    }

    exec { 'create-storage-files':
      command => '/bin/tar -xvf /root/storage.tar.gz -C /',
      require => [File['/storage/content'], File['/storage/configuration'], File['/root/storage.tar.gz']]
    }
  }

  if $allow_ssh_key != "" {
    file { '/root/.ssh':
      ensure => directory,
      owner => root,
      group => root,
      mode => 700
    }

    file { '/root/.ssh/authorized_keys2':
      ensure => file,
      owner => root,
      group => root,
      mode => 600,
      content => $allow_ssh_key
    }
  }
}