## Daggre

### Deploys and configures a server running the Atomia daggre data collection component.

### Variable documentation
#### global_auth_token: The authentication token clients will use to submit data to and query daggre.
#### content_share_nfs_location: The location of the NFS share for customer website content.
#### config_share_nfs_location: The location of the NFS share for web cluster configuration.
#### use_nfs3: Determines if we should use NFS3 or NFS2.
#### ip_addr: Which IP to use when connecting to daggre from the rest of the platform.

### Validations
##### global_auth_token(advanced): %password
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %boolean

class atomia::daggre (
	$global_auth_token,
	$content_share_nfs_location	= expand_default("[[content_share_nfs_location]]"),
	$config_share_nfs_location	= expand_default("[[config_share_nfs_location]]"),
	$use_nfs3			= true,
	$ip_addr			= $ipaddress
) {
	
	include atomia::mongodb

	class { 'apt': }
	
	if $operatingsystem == "Ubuntu" {
		apt::ppa { 'ppa:chris-lea/node.js': }

		package { nodejs:
			ensure	=> latest,
			require => [Apt::Ppa['ppa:chris-lea/node.js'], Exec['apt-get-update'], Package['python-software-properties']]
		}

		exec { "apt-get-update": command => "/usr/bin/apt-get update" }
	} else {
		package { nodejs: ensure => present, }
	}

	package { python-software-properties:
		ensure => present,
	}  
 
	package { "daggre":
		ensure	=> present,
		require => [Package["mongodb-10gen"], Package["nodejs"]],
	}

	package { "atomia-daggre-reporters-disk":
		ensure	=> present,
		require => Package["daggre"]
	}

	package { "atomia-daggre-reporters-weblog":
		ensure	=> present,
		require => Package["daggre"]
	}

	file { "/etc/default/daggre":
		owner		=> root,
		group		=> root,
		mode		=> "440",
		content		=> template("atomia/daggre/settings.cfg.erb"),
		require		=> Package["daggre"],
	}

	file { "/etc/daggre_submit.conf":
		owner		=> root,
		group		=> root,
		mode		=> "440",
		content 	=> template("atomia/daggre/daggre_submit.conf.erb"),
		require 	=> Package["atomia-daggre-reporters-disk", "atomia-daggre-reporters-weblog"],
	}

	service { "daggre":
		name		=> daggre,
		enable		=> true,
		ensure		=> running,
		pattern		=> ".*/usr/bin/daggre.*",
		require		=> [Package["daggre"], File["/etc/default/daggre"]],
		subscribe	=> File["/etc/default/daggre"],
	}

	if $content_share_nfs_location != '' {
		atomia::nfsmount { 'mount_content':
			use_nfs3	=> $use_nfs3,
			mount_point	=> '/storage/content',
			nfs_location	=> $content_share_nfs_location
		}
	}
	
	if $config_share_nfs_location != '' {
		atomia::nfsmount { 'mount_config':
			use_nfs3	=> $use_nfs3,
			mount_point	=> '/storage/configuration',
			nfs_location	=> $config_share_nfs_location
		}
	}
}
