class atomia::nfsmount(
	$apache_conf_dir,
	$iis_config_dir,
	$atomia_iis_config_nfs_location,
	$atomia_web_config_nfs_location,
	$atomia_web_content_nfs_location,
	$atomia_web_content_mount_point,
	$atomia_web_config_mount_point,
	$use_nfs3
) {
	if !defined(Package['nfs-common']) {
		package { nfs-common: ensure => present }
	}

	if $use_nfs3 {
		$fs_type = "nfs"
	} else {
		$fs_type = "nfs4"
	}

	if $atomia_web_content_nfs_location {

		mount { $atomia_web_content_mount_point:
			device => $atomia_web_content_nfs_location,
			fstype => $fs_type,
			remounts => false,
			options => "rw,noatime",
			ensure => mounted,
			require => File[$atomia_web_content_mount_point],
		}
	}

	if $litespeed_nfs_config {
		$config_path = "lsp"
	} else {
		$config_path = "apache"
	}

	if $atomia_web_config_nfs_location != "" {
	
		file { "$atomia_web_config_mount_point/all_configurations":
			ensure => directory,
			require => File["$atomia_web_config_mount_point"],
		}
		
		mount { "$atomia_web_config_mount_point/all_configurations":
			device => $atomia_web_config_nfs_location,
			fstype => $fs_type,
			remounts => false,
			options => "rw,noatime",
			ensure => mounted,
			require => File["$atomia_web_config_mount_point/all_configurations"],
		}
		
		if $apache_conf_dir {
			file { "$atomia_web_config_mount_point/all_configurations/$apache_conf_dir":
				ensure => directory,
				require => Mount["$atomia_web_config_mount_point/all_configurations"],
			}
			
			mount { $atomia_web_config_mount_point:
				device => "$atomia_web_config_nfs_location/$apache_conf_dir",
				fstype => $fs_type,
				remounts => false,
				options => "rw,noatime",
				ensure => mounted,
				require => File["$atomia_web_config_mount_point/all_configurations/$apache_conf_dir"],
			}
		}
	}
	
	if $atomia_iis_config_nfs_location != "" {
		mount { "$atomia_web_config_mount_point/$iis_config_dir":
			device => $atomia_iis_config_nfs_location,
			fstype => $fs_type,
			remounts => false,
			options => "rw,noatime",
			ensure => mounted,
			require => File["$atomia_web_config_mount_point/iis_config_dir"],
		}
	}

	file { $atomia_web_content_mount_point:
		ensure => directory,
		require => File["/storage"],
	}

	file { "$atomia_web_config_mount_point":
		ensure => directory,
		require => File["/storage"],
	}
	
	file { "$atomia_web_config_mount_point/iis_config_dir":
		ensure => directory,
		require => File["/storage"],
	}

	if !defined(File["/storage"]) {
		file { "/storage":
			ensure => directory,
		}
	}

	if $operatingsystem != "Debian" {
		service {'idmapd' :
			ensure => running,
			subscribe => File['/etc/idmapd.conf']
		}
	}
	else {
		service {'nfs-common' :
			ensure => running,
			subscribe => File['/etc/idmapd.conf']
		}
	}

        file { 'idmapd.conf' :
                path    => "/etc/idmapd.conf",
                ensure => 'file',
                content  => template('atomia/idmapd.conf'),
        }
	
	file { 'nfs-common' :
                path    => "/etc/default/nfs-common",
                ensure => 'file',
                content  => template('atomia/nfs-common'),
	}
}

