## Atomia SSH resource server

### Deploys and configures a SSH customer server.

### Variable documentation
#### cluster_ip: The virtual IP of the mail cluster.
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### content_share_nfs_location: The location of the NFS share for customer website content. Example: 192.168.33.21:/export/content

### Validations
##### cluster_ip: %ip
##### use_nfs3(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share

class atomia::sshserver (
  $content_share_nfs_location   = '',
  $use_nfs3                     = '1',
  $cluster_ip                   = '',
) {

  class { 'apt': }

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
}
