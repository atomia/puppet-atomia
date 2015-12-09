## Awstats

### Deploys and configures Awstats for statistics processing

### Variable documentation
#### agent_user: The username to require when accessing the awstats agent.
#### agent_password: The password to require when accessing the awstats agent.
#### ssl_enabled: Enable or disable SSL
#### content_share_nfs_location: The location of the NFS share for customer website content. If using the default setup with GlusterFS leave blank otherwise you need to fill it in.
#### configuration_share_nfs_location: The location of the NFS share for shared configuration. If using the default setup with GlusterFS leave blank otherwise you need to fill it in.
#### skip_mount: Toggles if we are to mount the content share or not.
#### ssl_cert_key: SSL key to use if ssl is enabled
#### ssl_cert_file: SSL cert to use if ssl is enabled

### Validations
##### agent_user(advanced): %username
##### agent_password(advanced): %password
##### ssl_enabled(advanced): %boolean
##### content_share_nfs_location(advanced): %nfs_share
##### configuration_share_nfs_location(advanced): %nfs_share
##### skip_mount(advanced): [%boolean
##### ssl_cert_key(advanced): .*
##### ssl_cert_file(advanced): .*



class atomia::awstats (
		$agent_user = "awstats",
		$agent_password,
		$ssl_enabled = false,
		$content_share_nfs_location = '',
		$configuration_share_nfs_location = '',
		$ssl_cert_key = "",
		$ssl_cert_file = "",
		$skip_mount        = false
	) {

  package { atomia-pa-awstats: ensure => present }
	package { atomiaprocesslogs: ensure => present }

	package { awstats: ensure => installed }
    package { procmail: ensure => installed }
	
	if !defined(Package['apache2-mpm-worker']) and !defined(Package['apache2-mpm-prefork']) and !defined(Package['apache2']) {
		package { apache2-mpm-worker: ensure => installed }
	}
	
	if $skip_mount == 'false' {

		
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
				nfs_location => $configuration_share_nfs_location
			}
		}
	}
	if $ssl_enabled == 'true' {
			$ssl_generate_var = "ssl"

			file { "/usr/local/awstats-agent/wildcard.key":
					owner   => root,
					group   => root,
					mode    => "440",
				  content => $ssl_cert_key,
					require => Package["atomia-pa-awstats"]
			}

			file { "/usr/local/awstats-agent/wildcard.crt":
					owner   => root,
					group   => root,
					mode    => "440",
					content => $ssl_cert_file,
					require => Package["atomia-pa-awstats"]
			}
	} else {
			$ssl_generate_var = "nossl"
	}


	file { "/usr/local/awstats-agent/settings.cfg":
			owner   => root,
			group   => root,
			mode    => "440",
			content => template("atomia/awstats/settings.cfg.erb"),
			require => Package["atomia-pa-awstats"]
	}

	service { awstats-agent:
			name => awstats-agent,
			enable => true,
			ensure => running,
			hasstatus => false,
			pattern => "/etc/init.d/awstats-agent start",
			subscribe => [ Package["atomia-pa-awstats"], File["/usr/local/awstats-agent/settings.cfg"] ],
	}

	file { "/etc/cron.d/awstats":
		ensure => absent
	}

	file { "/etc/statisticsprocess.conf":
			owner   => root,
			group   => root,
			mode    => "400",
			source  => "puppet:///modules/atomia/awstats/statisticsprocess.conf",
	}

	file { "/etc/cron.d/convertlogs":
			owner   => root,
			group   => root,
			mode    => "444",
			source  => "puppet:///modules/atomia/awstats/convertlogs",
	}
	
	file { "/storage/content/logs/iis_logs/convert_logs.sh":
			owner   => root,
			group   => root,
			mode    => "544",
			source  => "puppet:///modules/atomia/awstats/convert_logs.sh",
	}

	file { "/etc/apache2/conf-enabled/awstats.conf":
			owner   => root,
			group   => root,
			mode    => "444",
			source  => "puppet:///modules/atomia/awstats/awstats.conf",
			notify	=> Service["apache2"],
			require => Package['awstats'],
	}
	
	file { "/etc/awstats/awstats.conf.local":
			owner   => root,
			group   => root,
			mode    => "444",
			source  => "puppet:///modules/atomia/awstats/awstats.conf.local",
			require => Package['awstats'],
	}
	
	file { "/storage/content/systemservices/public_html/nostats.html":
			owner   => root,
			group   => root,
			mode    => "444",
			source  => "puppet:///modules/atomia/awstats/nostats.html",
	}

	if !defined(File['/etc/apache2/sites-available/default']) {
	        file { "/etc/apache2/sites-available/default":
			ensure	=> absent,
		}
	}

	if !defined(File['/etc/apache2/sites-enabled/000-default']) {
	        file { "/etc/apache2/sites-enabled/000-default":
			ensure	=> absent,
		}
	}

	if !defined(Service['apache2']) {
	        service { apache2:
			name => apache2,
			enable => true,
	                ensure => running,
		}
	}

	if !defined(Exec['force-reload-apache']) {
	        exec { "force-reload-apache":
			refreshonly => true,
			before => Service["apache2"],
			command => "/etc/init.d/apache2 force-reload",
		}
	}

	if !defined(Exec['/usr/sbin/a2enmod rewrite']) {
	        exec { "/usr/sbin/a2enmod rewrite":
			unless => "/usr/bin/test -f /etc/apache2/mods-enabled/rewrite.load",
			require => Package["apache2-mpm-worker"],
			notify => Exec["force-reload-apache"],
		}
        }

    file { '/etc/cron.d/rotate-awstats-logs':
        ensure  => present,
        content => "0 0 * * * root lockfile -r0 /var/run/rotate-awstats && (find /var/log/awstats/ -mtime +14 -exec rm -f '{}' '+'; rm -f /var/run/rotate-awstats.lock)"
    }

}

