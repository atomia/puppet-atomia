define atomia::nfsmount(
  $use_nfs3,
  $mount_point,
  $nfs_location,
  $nfs_type      = hiera('atomia::nfsmount::nfs_type', 'nfs'),
  $nfs_options   = hiera('atomia::nfsmount::nfs_options', 'rw,noatime'),
  $ad_domain     = hiera('atomia::active_directory::domain_name', ''),
) {


  if $nfs_type == 'nfs'
  {
    if $use_nfs3 == '1' {
      $fs_type = 'nfs'
    } else {
      $fs_type = 'nfs4'
    }
  }
  else
  {
    $fs_type = $nfs_type
  }

  if !defined(File['/storage']) {
    file { '/storage':
      ensure => directory,
    }
  }

  if !defined(File[$mount_point]) {
    file { $mount_point:
      ensure  => directory,
      require => File['/storage'],
      mode    => '0711',
    }
  }

  if $::osfamily != 'RedHat' {
    if !defined(Package['nfs-common']) {
      package { 'nfs-common': ensure => present }
    }

    mount { $mount_point:
      ensure   => mounted,
      device   => $nfs_location,
      fstype   => $fs_type,
      remounts => false,
      options  => $nfs_options,
      require  => [File[$mount_point], Package['nfs-common']],
    }

    if $::operatingsystem != 'Debian' {
      if !defined(Service['idmapd']){
        service {'idmapd' :
          ensure    => running,
          subscribe => File['/etc/idmapd.conf'],
          require   => [Package['nfs-common']],
        }
      }
    }
    else {
      if !defined(Service['nfs-common']){
        service {'nfs-common' :
          ensure    => running,
          subscribe => File['/etc/idmapd.conf']
        }
      }
    }

    if !defined(File['idmapd.conf']){
      file { 'idmapd.conf' :
        ensure  => 'file',
        path    => '/etc/idmapd.conf',
        content => template('atomia/nfsmount/idmapd.conf'),
      }
    }
    if !defined(File['nfs-common']){
      file { 'nfs-common' :
        ensure  => 'file',
        path    => '/etc/default/nfs-common',
        content => template('atomia/nfsmount/nfs-common'),
      }
    }

    }# CloudLinux specifics
    else
    {
      if !defined(Package['nfs-utils']) {
        package { 'nfs-utils': ensure => present }
      }

      mount { $mount_point:
        ensure   => mounted,
        device   => $nfs_location,
        fstype   => $fs_type,
        remounts => false,
        options  => $nfs_options,
        require  => [File[$mount_point]],
      }
    }

}
