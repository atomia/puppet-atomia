## Atomia installatron server

### Deploys and configures a server running the Installatron server.

### Variable documentation
#### license_key: The license key needed to use Installatron server.
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### content_share_nfs_location: The location of the NFS share for customer website content.

### Validations
##### license_key: ^.+$
##### use_nfs3(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share

class atomia::installatron (
		$license_key,
		$use_nfs3 = 1,
		$content_share_nfs_location = expand_default("[[content_share_nfs_location]]")
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

	atomia::nfsmount { 'mount_content':
		use_nfs3 => $use_nfs3,
		mount_point => '/storage/content',
		nfs_location => $content_share_nfs_location
	}
		

	service { 'apache2': 
		ensure		=> running,
		require		=> Package['apache2'],
	}

	exec { 'fetch-installatron-package':
		command		=> '/usr/bin/wget http://data.installatron.com/installatron-server_latest_all.deb -O /root/installatron-server_latest_all.deb',
		unless		=> '/bin/ls -l /root/installatron-server_latest_all.deb | /bin/grep -c installatron',
		require		=> Package['curl'],
		notify		=> Exec['install-installatron-package']
	}

	exec { 'install-installatron-package': 
		command		=> '/etc/profile.d/installatron-key.sh && /usr/bin/dpkg -i /root/installatron-server_latest_all.deb',
		unless		=> '/usr/bin/dpkg -l | /bin/grep -c installatron',
		onlyif		=> '/bin/ls /root/installatron-server_latest_all.deb | /bin/grep -c installatron',
		require		=> File['/etc/profile.d/installatron-key.sh'],
	}

	file { '/etc/apache2/sites-enabled/000-default':
		ensure		=> absent,
		require		=> Package["apache2"],
		notify		=> Service["apache2"]
	}

	file { '/etc/apache2/sites-enabled/installatron.conf':
		ensure		=> present,
		source		=> "puppet:///modules/atomia/installatron/vhost.conf",
		require		=> Package["apache2"],
		notify		=> Service["apache2"]
	}

	file { '/etc/profile.d/installatron-key.sh':
		mode		=> "0755",
		content => "export KEY=${license_key}",
	}

	file { '/usr/local/installatron/http/index.php':
		mode	=> "0644",
	}
}
