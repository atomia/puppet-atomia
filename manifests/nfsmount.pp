define atomia::nfsmount(
		$use_nfs3,
		$mount_point,
		$nfs_location,
		$nfs_type = hiera('atomia::nfsmount::nfs_type', 'nfs'),
		$nfs_options = hiera('atomia::nfsmount::nfs_options', 'rw,nfsvers=3,noatime'),
		$ad_domain = "hiera('atomia::adjoin::domain_name', ''),"
) {
	if !defined(Package['nfs-common']) {
		package { nfs-common: ensure => present }
	}

	if $nfs_type == "nfs" 
	{
		if $use_nfs3 {
			$fs_type = "nfs"
		} else {
			$fs_type = "nfs4"
		}
	}
	else
	{
		$fs_type = $nfs_type
	}

    mount { $mount_point:
      device => $nfs_location,
      fstype => $fs_type,
      remounts => false,
      options => $nfs_options,
      ensure => mounted,
      require => [File[$mount_point], Package['nfs-common']],
    }
  
  if !defined(File["/storage"]) {
    file { "/storage":
      ensure => directory,
    }
  }

  if !defined(File[$mount_point]) {
	file { $mount_point:
		ensure => directory,
		require => File["/storage"],
        mode    => 711,
	}
}

	
	if $operatingsystem != "Debian" {
	  if !defined(Service["idmapd"]){
			service {'idmapd' :
				ensure => running,
				subscribe => File['/etc/idmapd.conf'],
				require => [Package['nfs-common']],
			}
		}
	}
	else {
	  if !defined(Service["nfs-common"]){
			service {'nfs-common' :
				ensure => running,
				subscribe => File['/etc/idmapd.conf']
		   }
	   }
	 }


  if !defined(File['idmapd.conf']){
	  file { 'idmapd.conf' :
	    path    => "/etc/idmapd.conf",
	    ensure => 'file',
	    content  => template('atomia/idmapd.conf'),
	  }  
  }
	if !defined(File['nfs-common']){
		file { 'nfs-common' :
	    path    => "/etc/default/nfs-common",
	    ensure => 'file',
	    content  => template('atomia/nfs-common'),
		}
	}
}

