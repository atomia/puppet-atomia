## Daggre

### Deploys and configures a server running the Atomia daggre data collection component.

### Variable documentation
#### global_auth_token: The authentication token clients will use to submit data to and query daggre.
#### content_share_nfs_location: The location of the NFS share for customer website content. If using the default setup with GlusterFS leave blank otherwise you need to fill it in. Example: 192.168.33.21:/export/content.
#### config_share_nfs_location: The location of the NFS share for web cluster configuration. If using the default setup with GlusterFS leave blank otherwise you need to fill it in. Example: 192.168.33.21:/export/configuration.
#### use_nfs3: Determines if we should use NFS3 or NFS2.
#### ip_addr: Which IP to use when connecting to daggre from the rest of the platform.
#### cloudlinux_database: Enable if server is to be used in conjunction with CloudLinux web servers
#### cloudlinux_database_password: The CloudLinux database server password
#### local_address: Local address for the agent
#### mongo_admin_user: The admin username for the MongoDB.
#### mongo_admin_pass: The admin password for the MongoDB.
#### mongo_daggre_user: The username that the cronagent will use to connect to MongoDB.
#### mongo_daggre_pass: The password that the cronagent will use to connect to MongoDB.
#### mongo_db_name: The database name that the cronagent will use.

### Validations
##### ip_addr(advanced): %hostname
##### global_auth_token(advanced): %password
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %int_boolean
##### cloudlinux_database(advanced): %int_boolean
##### cloudlinux_database_password(advanced): %password
##### local_address(advanced): .*
##### mongo_admin_user(advanced): ^[^[[:space:]]]+$
##### mongo_admin_pass(advanced): %password
##### mongo_daggre_user(advanced): ^[^[[:space:]]]+$
##### mongo_daggre_pass(advanced): %password
##### mongo_db_name(advanced): .*

class atomia::daggre (
  $global_auth_token,
  $content_share_nfs_location   = '',
  $config_share_nfs_location    = '',
  $use_nfs3                     = '1',
  $ip_addr                      = '',
  $cloudlinux_database          = '0',
  $cloudlinux_database_password = 'atomia123',
  $local_address                = 'localhost',
  $mongo_admin_user             = 'admin',
  $mongo_admin_pass             = '',
  $mongo_daggre_user            = 'daggre',
  $mongo_daggre_pass            = '',
  $mongo_db_name                = 'daggre'
) {

  class { 'apt': }

  class {'::mongodb::globals':
    manage_package_repo => true
  } ->
  class {'::mongodb::client': } ->
  class {'::mongodb::server':
    auth           => true,
    create_admin   => true,
    store_creds    => true,
    admin_username => $mongo_admin_user,
    admin_password => $mongo_admin_pass,
    dbpath_fix     => false
  }

  if $::lsbdistrelease == '16.04' {
    file {'/etc/systemd/system/mongod.service':
       source => 'puppet:///modules/atomia/mongodb/mongod.service',
       ensure => present
    }
  }

  if $::operatingsystem == 'Ubuntu' {
    apt::source { 'nodesource_0.12':
      location => 'https://deb.nodesource.com/node_0.12',
      release  => $::codename,
      repos    => 'main',
      key      => {
        id     => '9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280',
        source => 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key'
      },
      include  => {
        'src' => true,
        'deb' => true,
      },
    }

    package { 'nodejs':
      ensure  => latest,
      require => [ Apt::Source['nodesource_0.12'] ]
    }
  } else {
    package { 'nodejs': ensure => present, }
  }

  package { 'python-software-properties':
    ensure => present,
  }

  package { 'daggre':
    ensure  => present,
    require => [Class['mongodb::server'], Package['nodejs']],
  }

  package { 'atomia-daggre-reporters-disk':
    ensure  => present,
    require => Package['daggre']
  }

  package { 'atomia-daggre-reporters-weblog':
    ensure  => present,
    require => Package['daggre']
  }

  mongodb_user { $mongo_daggre_user:
    ensure        => present,
    name          => $mongo_daggre_user,
    password_hash => mongodb_password($mongo_daggre_user, $mongo_daggre_pass),
    database      => $mongo_db_name,
    roles         => [ 'readWrite', 'dbAdmin' ],
    require       => Package['daggre']
  }


  file { '/etc/default/daggre':
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template('atomia/daggre/settings.cfg.erb'),
    require => Package['daggre'],
  }

  file { '/etc/daggre_submit.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template('atomia/daggre/daggre_submit.conf.erb'),
    require => Package['atomia-daggre-reporters-disk', 'atomia-daggre-reporters-weblog'],
  }

  service { 'daggre':
    ensure    => running,
    enable    => true,
    status    => 'test `ps aux | grep /usr/bin/daggre | grep -v grep | wc -l` -eq 1',
    require   => [Package['daggre'], File['/etc/default/daggre']],
    subscribe => File['/etc/default/daggre'],
  }

  $test_env = hiera('atomia::config::test_env', '0')

  if ($test_env == '0') and ($content_share_nfs_location == '') {
    $gluster_hostname = hiera('atomia::glusterfs::gluster_hostname','')
    package { 'glusterfs-client': ensure => present, }

    if !defined(File['/storage']) {
      file { '/storage':
        ensure => directory,
      }
    }

    fstab::mount { '/storage/content':
      ensure  => 'mounted',
      device  => "${gluster_hostname}:/web_volume",
      options => 'defaults,_netdev',
      fstype  => 'glusterfs',
      require => [Package['glusterfs-client'],File['/storage']],
    }
    fstab::mount { '/storage/configuration':
      ensure  => 'mounted',
      device  => "${gluster_hostname}:/config_volume",
      options => 'defaults,_netdev',
      fstype  => 'glusterfs',
      require => [ Package['glusterfs-client'],File['/storage']],
    }
  }
  elsif($test_env == '0')
  {
    atomia::nfsmount { 'mount_content':
      use_nfs3     => 1,
      mount_point  => '/storage/content',
      nfs_location => $content_share_nfs_location
    }

    atomia::nfsmount { 'mount_configuration':
      use_nfs3     => 1,
      mount_point  => '/storage/configuration',
      nfs_location => $config_share_nfs_location
    }
  }
  else
  {
    $dirs = [
      '/storage',
      '/storage/content/',
      '/storage/configuration'
    ]

    file { $dirs:
      ensure => 'directory',
    } ->
    file { '/root/storage.tar.gz':
      ensure => file,
      source => 'puppet:///modules/atomia/fsagent/storage.tar.gz'
    } ->
    exec { 'create-storage-files':
      command => '/bin/tar -xvf /root/storage.tar.gz -C /',
      unless  => '/usr/bin/test -d /storage/content/00'
    }
  }

  if $cloudlinux_database == '1' {

    package { 'atomia-daggre-reporters-cloudlinux':
      ensure  => present,
    }

    package { 'postgresql-contrib':
      ensure  => present,
    }

    package { 'libdbi-perl':
      ensure  => present,
    }

    package { 'libdbd-pg-perl':
      ensure  => present,
    }

    class { 'postgresql::server':
      ip_mask_allow_all_users => '0.0.0.0/0',
      listen_addresses        => '*',
      ipv4acls                => ['host all atomia 0.0.0.0/0 md5']
    }

    postgresql::server::db { 'lve':
      user     => 'atomia-lve',
      password => postgresql_password('atomia-lve', $cloudlinux_database_password),
    }

    postgresql::server::pg_hba_rule { 'allow network acces for atomia user':
      description => 'Open up postgresql for access for Atomia user',
      type        => 'host',
      database    => 'all',
      user        => 'atomia-lve',
      address     => '0.0.0.0/0',
      auth_method => 'password',
    }
  }
}
