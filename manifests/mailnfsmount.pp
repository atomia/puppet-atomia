class atomia::mailnfsmount(
	$storage_nfs_location,
	$use_nfs3 = 0
) {
	if !defined(Package['nfs-common']) {
		package { nfs-common: ensure => latest }
	}

	if $use_nfs3 == 1 {
		$fs_type = "nfs"
	} else {
		$fs_type = "nfs4"
	}

	group { "virtual":
		name => "virtual",
		ensure => "present",
		gid => 2000,
	}

	user { "virtual":
		name => "virtual",
		ensure => "present",
		uid => 2000,
		gid => 2000,
		home => "/var/spool/mail",
	}

	if storage_nfs_location {
		mount { "/storage/mailcontent":
			device => $storage_nfs_location,
			fstype => $fs_type,
			remounts => false,
			options => "rw",
			ensure => mounted,
			require => File["/storage/mailcontent"],
		}

		file { "/storage/mailcontent":
			ensure => directory,
			require => File["/storage"],
			owner => "virtual",
			group => "virtual",
			mode => 775,
		}
	}

	if !defined(File["/storage"]) {
		file { "/storage":
			ensure => directory,
		}
	}
}

