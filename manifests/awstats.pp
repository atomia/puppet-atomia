## Awstats

### Deploys and configures Awstats for statistics processing

### Variable documentation
#### agent_user: The username to require when accessing the awstats agent.
#### agent_password: The password to require when accessing the awstats agent.
#### ssl_enabled: Enable or disable SSL
#### content_share_nfs_location: The location of the NFS share for customer website content. If using the default setup with GlusterFS leave blank otherwise you need to fill it in. Example: 192.168.33.21:/export/content
#### configuration_share_nfs_location: The location of the NFS share for shared configuration. If using the default setup with GlusterFS leave blank otherwise you need to fill it in. Example: 192.168.33.21:/export/configuration
#### skip_mount: Toggles if we are to mount the content share or not.
#### ssl_cert_key: SSL key to use if ssl is enabled
#### ssl_cert_file: SSL cert to use if ssl is enabled
#### server_ip: Awstats server ip

### Validations
##### agent_user(advanced): %username
##### agent_password(advanced): %password
##### ssl_enabled(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share
##### configuration_share_nfs_location(advanced): %nfs_share
##### skip_mount(advanced): %int_boolean
##### ssl_cert_key(advanced): .*
##### ssl_cert_file(advanced): .*
##### server_ip(advanced): .*

class atomia::awstats (
  $agent_user                       = 'awstats',
  $agent_password,
  $ssl_enabled                      = '0',
  $content_share_nfs_location       = '',
  $configuration_share_nfs_location = '',
  $ssl_cert_key                     = '',
  $ssl_cert_file                    = '',
  $skip_mount                       = '0',
  $server_ip                        = $ipaddress
) {

  package { 'atomia-pa-awstats': ensure => present }
  package { 'atomiaprocesslogs': ensure => present }

  package { 'awstats': ensure => installed }
  package { 'procmail': ensure => installed }

  if !defined(Package['apache2-mpm-worker']) and !defined(Package['apache2-mpm-prefork']) and !defined(Package['apache2']) {
    if $::lsbdistrelease == '16.04' {
      package { [
        'apache2',
      ]:
        ensure => installed,
      }
    } else {
      package { [
        'apache2-mpm-worker',
        'apache2',
      ]:
        ensure => installed,
      }
    }
  }

  if $skip_mount == '0' {


    $internal_zone = hiera('atomia::internaldns::zone_name','')

    if $content_share_nfs_location == '' {
      package { 'glusterfs-client': ensure => present, }

      if !defined(File['/storage']) {
        file { '/storage':
          ensure => directory,
        }
      }

      fstab::mount { '/storage/content':
        ensure  => 'mounted',
        device  => "gluster.${internal_zone}:/web_volume",
        options => 'defaults,_netdev',
        fstype  => 'glusterfs',
        require => [Package['glusterfs-client'],File['/storage']],
      }
      fstab::mount { '/storage/configuration':
        ensure  => 'mounted',
        device  => "gluster.${internal_zone}:/config_volume",
        options => 'defaults,_netdev',
        fstype  => 'glusterfs',
        require => [ Package['glusterfs-client'],File['/storage']],
      }
    }
    else
    {
      if !defined(File['/storage']) {
        file { '/storage':
          ensure => directory,
        }
      }

      atomia::nfsmount { 'mount_content':
        use_nfs3     => '1',
        mount_point  => '/storage/content',
        nfs_location => $content_share_nfs_location
      }

      atomia::nfsmount { 'mount_configuration':
        use_nfs3     => '1',
        mount_point  => '/storage/configuration',
        nfs_location => $configuration_share_nfs_location
      }
    }
  }
  if $ssl_enabled == '1' {
    $ssl_generate_var = 'ssl'

    file { '/usr/local/awstats-agent/wildcard.key':
      owner   => root,
      group   => root,
      mode    => '0440',
      content => $ssl_cert_key,
      require => Package['atomia-pa-awstats']
    }

    file { '/usr/local/awstats-agent/wildcard.crt':
      owner   => root,
      group   => root,
      mode    => '0440',
      content => $ssl_cert_file,
      require => Package['atomia-pa-awstats']
    }
  } else {
    $ssl_generate_var = 'nossl'
  }


  file { '/usr/local/awstats-agent/settings.cfg':
    owner   => root,
    group   => root,
    mode    => '0440',
    content => template('atomia/awstats/settings.cfg.erb'),
    require => Package['atomia-pa-awstats']
  }

  service { 'awstats-agent':
    ensure    => running,
    name      => awstats-agent,
    enable    => true,
    hasstatus => false,
    pattern   => '/etc/init.d/awstats-agent start',
    subscribe => [ Package['atomia-pa-awstats'], File['/usr/local/awstats-agent/settings.cfg'] ],
  }

  file { '/etc/cron.d/awstats':
    ensure => absent
  }

  file { '/etc/statisticsprocess.conf':
    owner  => root,
    group  => root,
    mode   => '0400',
    source => 'puppet:///modules/atomia/awstats/statisticsprocess.conf',
  }

  file { '/etc/cron.d/convertlogs':
    owner  => root,
    group  => root,
    mode   => '0444',
    source => 'puppet:///modules/atomia/awstats/convertlogs',
  }

  file { '/storage/content/logs/iis_logs/convert_logs.sh':
    owner  => root,
    group  => root,
    mode   => '0544',
    source => 'puppet:///modules/atomia/awstats/convert_logs.sh',
  }

  file { '/etc/apache2/conf-available/awstats.conf':
    owner   => root,
    group   => root,
    mode    => '0444',
    source  => 'puppet:///modules/atomia/awstats/awstats.conf',
    require => [Package['awstats'],Package['atomia-pa-awstats']],
  }

  exec { '/usr/sbin/a2enconf awstats.conf':
    unless  => '/usr/bin/test -f /etc/apache2/config-enabled/awstats.conf',
    require => [Package['awstats'],Package['atomia-pa-awstats']],
    notify  => Service['apache2'],
  }

  file { '/etc/awstats/awstats.conf.local':
    owner   => root,
    group   => root,
    mode    => '0444',
    source  => 'puppet:///modules/atomia/awstats/awstats.conf.local',
    require => Package['awstats'],
  }

  file { '/storage/content/systemservices/public_html/nostats.html':
    owner  => root,
    group  => root,
    mode   => '0444',
    source => 'puppet:///modules/atomia/awstats/nostats.html',
  }

  if !defined(File['/etc/apache2/sites-available/default']) {
    file { '/etc/apache2/sites-available/default':
      ensure  => absent,
    }
  }

  if !defined(File['/etc/apache2/sites-enabled/000-default']) {
    file { '/etc/apache2/sites-enabled/000-default.conf':
      ensure  => absent,
    }
  }

  if !defined(Service['apache2']) {
    service { 'apache2':
      ensure => running,
      enable => true,
    }
  }

  if !defined(Exec['force-reload-apache']) {
    exec { 'force-reload-apache':
      refreshonly => true,
      before      => Service['apache2'],
      command     => '/etc/init.d/apache2 force-reload',
    }
  }

  if !defined(Exec['/usr/sbin/a2enmod rewrite']) {
    exec { '/usr/sbin/a2enmod rewrite':
      unless  => '/usr/bin/test -f /etc/apache2/mods-enabled/rewrite.load',
      require => Package['apache2'],
      notify  => Exec['force-reload-apache'],
    }
  }

  if !defined(Exec['/usr/sbin/a2enmod authz_groupfile']) {
    exec { '/usr/sbin/a2enmod authz_groupfile':
      unless  => '/usr/bin/test -f /etc/apache2/mods-enabled/authz_groupfile.load',
      require => Package['apache2'],
      notify  => Exec['force-reload-apache'],
    }
  }

  file { '/etc/cron.d/rotate-awstats-logs':
    ensure  => present,
    content => "0 0 * * * root lockfile -r0 /var/run/rotate-awstats && (find /var/log/awstats/ -mtime +14 -exec rm -f '{}' '+'; rm -f /var/run/rotate-awstats.lock)"
  }

  #Create apache group so the regular www-data can access folder with gid 48 and update the service (applies to cloudlinux)
  $use_rhel_apache_gid = hiera('atomia::config::use_cloudlinux', '')
  if $use_rhel_apache_gid == '1' {
    group { 'apache':
      ensure => present,
      gid    => '48'
    }
    file { '/etc/apache2/envvars':
      owner  => root,
      group  => root,
      mode   => '0644',
      source => 'puppet:///modules/atomia/awstats/envvars',
      notify  => Service['apache2']
    }
  }
}

