## Atomia installatron server

### Deploys and configures a server running the Installatron server.

### Variable documentation
#### license_key: The license key needed to use Installatron server.
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### content_share_nfs_location: The location of the NFS share for customer website content. Leave blank if using the default GlusterFS setup, otherwise fill it in.
#### installatron_hostname: The hostname of the Installatron server
#### authentication_key: You will need to get this after installation is complete, you can find it with the command grep key /usr/local/installatron/etc/settings.ini, paste it here and run provisioning again

### Validations
##### license_key: ^.+$
##### authentication_key: .*
##### use_nfs3(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share
##### installatron_hostname(advanced): .*

class atomia::installatron (
  $license_key,
  $use_nfs3                   = '1',
  $content_share_nfs_location = '',
  $installatron_hostname      = $fqdn,
  $authentication_key
) {

  package { [
    'apache2',
    'curl',
    'perl',
    'php5',
    'php5-gd',
    'libapache2-mod-php5',
    'php5-sqlite'
  ]: ensure => installed }

  if !defined(File['/storage']) {
    file { '/storage':
      ensure => directory,
    }
  }


  if $content_share_nfs_location == '' {
    package { 'glusterfs-client': ensure => present, }
    $internal_zone = hiera('atomia::internaldns::zone_name','')
    fstab::mount { '/storage/content':
      ensure  => 'mounted',
      device  => "gluster.${internal_zone}:/web_volume",
      options => 'defaults,_netdev',
      fstype  => 'glusterfs',
      require => [Package['glusterfs-client'],File['/storage']],
    }
  }
  else {
    atomia::nfsmount { 'mount_content':
      use_nfs3     => $use_nfs3,
      mount_point  => '/storage/content',
      nfs_location => $content_share_nfs_location
    }
    if !defined(File['/storage/content']) {
      file { '/storage/content':
        ensure  => directory,
        require => File['/storage'],
      }
    }
  }


  service { 'apache2':
    ensure  => running,
    require => Package['apache2'],
  }

  exec { 'fetch-installatron-package':
    command => '/usr/bin/wget http://data.installatron.com/installatron-server_latest_all.deb -O /root/installatron-server_latest_all.deb',
    unless  => '/bin/ls -l /root/installatron-server_latest_all.deb | /bin/grep -c installatron',
    require => Package['curl'],
    notify  => Exec['install-installatron-package']
  }

  exec { 'install-installatron-package':
    command => '/etc/profile.d/installatron-key.sh && /usr/bin/dpkg -i /root/installatron-server_latest_all.deb',
    unless  => '/usr/bin/dpkg -l | /bin/grep -c installatron',
    onlyif  => '/bin/ls /root/installatron-server_latest_all.deb | /bin/grep -c installatron',
    require => File['/etc/profile.d/installatron-key.sh'],
  }

  file { '/etc/apache2/sites-enabled/000-default.conf':
    ensure  => absent,
    require => Package['apache2'],
    notify  => Service['apache2']
  }

  file { '/etc/apache2/sites-enabled/installatron.conf':
    ensure  => present,
    source  => 'puppet:///modules/atomia/installatron/vhost.conf',
    require => Package['apache2'],
    notify  => Service['apache2']
  }

  file { '/etc/profile.d/installatron-key.sh':
    mode    => '0755',
    content => "export KEY=${license_key}",
  }

  file { '/usr/local/installatron/http/index.php':
    mode  => '0644',
  }
}
