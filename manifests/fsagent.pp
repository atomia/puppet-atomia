## Atomia filesystem agent

### Deploys and configures a server running the Atomia filesystem agent.

### Variable documentation
#### username: The username to require when accessing the filesystem agent.
#### password: The password to require when accessing the filesystem agent.
#### fsagent_ip: The IP or hostname used to connect to the filesystem agent from the rest of the platform.
#### content_share_nfs_location: The location of the NFS share for customer website content. If using the default setup with GlusterFS leave blank otherwise you need to fill it in.
#### config_share_nfs_location: The location of the NFS share for shared configuration. If using the default setup with GlusterFS leave blank otherwise you need to fill it in.
#### skip_mount: Toggles if we are to mount the content share or not.
#### enable_config_agent: If set then we also setup a separate fsagent instance for accessing the web cluster configuration share.
#### create_storage_files: Toggles if we are to create initial storage directory structure if missing.
#### allow_ssh_key: If set then this SSH key will have access to the machine as root.

### Validations
##### username(advanced): %username
##### password(advanced): %password
##### fsagent_ip(advanced): %ip_or_hostname
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### skip_mount(advanced): %boolean
##### enable_config_agent(advanced): %boolean
##### create_storage_files(advanced): %boolean
##### allow_ssh_key(advanced): .*

class atomia::fsagent (
	$username			= "fsagent",
	$password,
	$fsagent_ip			= $fqdn,
	$content_share_nfs_location	= "",
	$config_share_nfs_location	= "",
	$skip_mount			= false,
	$enable_config_agent		= false,
	$create_storage_files		= true,
	$allow_ssh_key			= "",
) {
	


	package { python-software-properties: ensure => present }

	package { python: ensure => present }

	package { 'g++': ensure => present }

	package { make: ensure => present }

	package { procmail: ensure => present }

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

	package { atomia-fsagent: ensure => present, require => Package["nodejs"] }

	if !$skip_mount {
		
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

	if !defined(File["/storage"]) {
		file { "/storage":
			ensure => directory,
		}
	}

	if !defined(File["/storage/content"]) {
		file { "/storage/content":
			ensure => directory,
			require => File["/storage"],
		}
	}

	file { "/storage/content/backup":
		ensure => "directory",
		owner  => root,
		group  => root,
		mode	 => "710",
		require => File["/storage/content"],
	}

	file { "/etc/default/fsagent":
		owner		=> root,
		group		=> root,
		mode		=> "440",
		content => template("atomia/fsagent/settings.cfg.erb"),
		require => [Package["atomia-fsagent"], File["/storage/content/backup"]],
	}

	file { "/storage/configuration":
		ensure => directory,
		mode	 => "711",
		require => File["/storage"],
	}

	file { "/etc/cron.d/clearsessions":
		ensure	=> file,
		content => "15 * * * * root lockfile -r0 /var/run/clearsession.lock && (find /storage/configuration/php_session_path -mtime +2 -exec rm -f '{}' '+'; rm -f /var/run/clearsession.lock) \n"
	}

	if $enable_config_agent {
		file { "/etc/default/fsagent-ssl":
			owner		=> root,
			group		=> root,
			mode		=> "440",
			ensure	=> present,
			content => template("atomia/fsagent/settings-ssl.cfg.erb"),
			require => [Package["atomia-fsagent"]],
		}

		file { "/etc/init.d/atomia-fsagent-ssl":
			owner		=> root,
			group		=> root,
			mode		=> "755",
			ensure	=> present,
			content => template("atomia/fsagent/atomia-fsagent-ssl.erb"),
			require => [Package["atomia-fsagent"], File["/etc/default/fsagent-ssl"]],
		}

		service { atomia-fsagent-ssl:
			name			=> atomia-fsagent-ssl,
			enable		=> true,
			ensure		=> running,
			subscribe => [Package["atomia-fsagent"], File["/etc/default/fsagent-ssl"]],
			require		=> [Service["atomia-fsagent"], File["/etc/init.d/atomia-fsagent-ssl"]],
		}
	}

	service { atomia-fsagent:
		name		=> atomia-fsagent,
		enable		=> true,
		ensure		=> running,
		subscribe	=> [Package["atomia-fsagent"], File["/etc/default/fsagent"]],
	}

	if $create_storage_files {
		file { '/root/storage.tar.gz':
			ensure => file,
			source => "puppet:///modules/atomia/fsagent/storage.tar.gz",
		}

		if $skip_mount {
			exec { 'create-storage-files':
				command => '/bin/tar -xvf /root/storage.tar.gz -C /',
				require => [ File['/storage/content'],  File['/storage/configuration'], File['/root/storage.tar.gz'] ],
				unless => '/usr/bin/test -d /storage/content/00'
			}
		} else {
			exec { 'create-storage-files':
				command => '/bin/tar -xvf /root/storage.tar.gz -C /',
				require => [
					File['/storage/content'],  File['/storage/configuration'], File['/root/storage.tar.gz'],
					Mount['/storage/content'],
					Mount['/storage/configuration'],
				],
				unless => '/usr/bin/test -d /storage/content/00'
			}
		}
	}

	if $allow_ssh_key != "" {
		file { '/root/.ssh':
			ensure => directory,
			owner => root,
			group => root,
			mode => "700"
		}

		file { '/root/.ssh/authorized_keys2':
			ensure => file,
			owner => root,
			group => root,
			mode => "600",
			content => $allow_ssh_key
		}
	}
}
