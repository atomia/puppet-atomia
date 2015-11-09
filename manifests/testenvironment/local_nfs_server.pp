# Sets up a local nfs server for test purposes with the shares required for atomia
class atomia::testenvironment::local_nfs_server(
	$hostip='127.0.0.1',
	$content_share_nfs_location=expand_default('[[content_share_nfs_location]]'),
	$config_share_nfs_location=expand_default('[[config_share_nfs_location]]')
) {
 
  Package['nfs-kernel-server'] -> Service['nfs-kernel-server']

  package { 'nfs-kernel-server': ensure => present }

  service { 'nfs-kernel-server':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    pattern    => 'rpc.mountd',
  }


  file { '/export': ensure => directory, }

  file { '/export/configuration':
      ensure  => directory,
      require => File["/export"],
      mode    => "755"
 }
    
  file { '/export/mail':
    ensure  => directory,
    require => File["/export"],
    mode    => "755"
  }  
  file { '/export/content':
      ensure  => directory,
      require => File["/export"],
      mode    => "755"
  }
  ->
  file {'/etc/exports':
    content => "/export/configuration 192.168.33.0/24(rw,async,no_root_squash,no_subtree_check)
/export/content 192.168.33.0/24(rw,async,no_root_squash,no_subtree_check)
/export/mail 192.168.33.0/24(rw,async,no_root_squash,no_subtree_check)
",
  require => Package['nfs-kernel-server'],
  notify => Service['nfs-kernel-server'],}
  ->
  mount { '/storage/content':
    device => $content_share_nfs_location,
    fstype => "nfs",
    remounts => false,
    options => "rw,noatime",
    ensure => mounted,
    require => [File['/storage/content'],File['/export/content'], File['/etc/exports']],
  }  
  mount { '/storage/configuration':
    device => $config_share_nfs_location,
    fstype => "nfs",
    remounts => false,
    options => "rw,noatime",
    ensure => mounted,
    require => [File['/storage/configuration'],File['/export/content'], File['/etc/exports']],
  }  
}
