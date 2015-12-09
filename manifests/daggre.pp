## Daggre

### Deploys and configures a server running the Atomia daggre data collection component.

### Variable documentation
#### global_auth_token: The authentication token clients will use to submit data to and query daggre.
#### content_share_nfs_location: The location of the NFS share for customer website content. If using the default setup with GlusterFS leave blank otherwise you need to fill it in.
#### config_share_nfs_location: The location of the NFS share for web cluster configuration. If using the default setup with GlusterFS leave blank otherwise you need to fill it in.
#### use_nfs3: Determines if we should use NFS3 or NFS2.
#### ip_addr: Which IP to use when connecting to daggre from the rest of the platform.

### Validations
##### ip_addr(advanced): %password
##### global_auth_token(advanced): %password
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %boolean

class atomia::daggre (
	$global_auth_token,
	$content_share_nfs_location	= '',
	$config_share_nfs_location	= '',
	$use_nfs3			= true,
	$ip_addr			= $ipaddress
) {
	
	include atomia::mongodb

	class { 'apt': }
	
	if $operatingsystem == "Ubuntu" {
		apt::source { 'nodesource_0.12':
			location	=> 'https://deb.nodesource.com/node_0.12',
			release		=> $codename,
			repos		=> 'main',
			key		=> {
				id	=> "9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280",
				source	=> 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key'
  			},
			include		=> {
				'src' => true,
				'deb' => true,
			},
		}

		package { nodejs:
			ensure	=> latest,
			require => [ Apt::Source['nodesource_0.12'] ]
		}
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

		$internal_zone = hiera('atomia::internaldns::zone_name','')
		
		if $content_share_nfs_location == '' {
			package { 'glusterfs-client': ensure => present, }
			
			if !defined(File["/storage"]) {
				file { "/storage":
				ensure => directory,
				}
			}
			
			fstab::mount { '/storage/content':
				ensure  => 'mounted',
				device  => "gluster.${internal_zone}:/web_volume",
				options => 'defaults,_netdev',
				fstype  => 'glusterfs',
				require => [Package['glusterfs-client'],File["/storage"]],
			}	
			fstab::mount { '/storage/configuration':
				ensure  => 'mounted',
				device  => "gluster.${internal_zone}:/config_volume",
				options => 'defaults,_netdev',
				fstype  => 'glusterfs',
				require => [ Package['glusterfs-client'],File["/storage"]],
			}			
    	}
		else
		{
			atomia::nfsmount { 'mount_content':
				use_nfs3		 => 1,
				mount_point  => '/storage/content',
				nfs_location => $content_share_nfs_location
			}
	
			atomia::nfsmount { 'mount_configuration':
				use_nfs3		 => 1,
				mount_point  => '/storage/configuration',
				nfs_location => $config_share_nfs_location
			}
		}
}
