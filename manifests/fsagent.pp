class atomia::fsagent(
	$username = "fsagent",
	$password,
	$content_share_nfs_location,
	$skip_mount        = 0,
	) {

	package { python-software-properties: ensure => present }
	package { python: ensure => present}
	package { 'g++': ensure => present }
	package { make: ensure => present }

	class { 'apt': }

	if $operatingsystem == "Ubuntu" {
		apt::ppa { 'ppa:chris-lea/node.js': }
	
		package { nodejs:
			ensure => present,
			require => Apt::Ppa['ppa:chris-lea/node.js']
		}
	}
	else {
                package { nodejs:
                        ensure => present,
                }
	}

	if $atomia_linux_software_auto_update {
		package { atomia-fsagent: ensure => latest }
	} else {
		package { atomia-fsagent: ensure => present }
	}
	if($skip_mount == 0){
		atomia::nfsmount { 'mount_content':
			use_nfs3 => 1,
			mount_point => '/storage/content',
			nfs_location => $content_share_nfs_location
		}
	}

        file { "/storage/content/backup":
            	ensure => "directory",
                owner   => root,
                group   => root,
                mode    => 710,
       }


        file { "/etc/default/fsagent":
                owner   => root,
                group   => root,
                mode    => 440,
                content =>  template("atomia/fsagent/settings.cfg.erb"),
                require => [ Package["atomia-fsagent"], File["/storage/content/backup"] ],
        }

		if $fs_agent_ssl {
			
			file { "/etc/default/fsagent-ssl":
                owner   => root,
                group   => root,
                mode    => 440,
				ensure  => present,
                content => template("atomia/fsagent/settings-ssl.cfg.erb"),
                require => [ Package["atomia-fsagent"] ],
			}
			
			file { "/etc/init.d/atomia-fsagent-ssl":
                owner   => root,
                group   => root,
                mode    => 755,
				ensure  => present,
                content => template("atomia/fsagent/atomia-fsagent-ssl.erb"),
                require => [ Package["atomia-fsagent"] , File["/etc/default/fsagent-ssl"] ],
			}
			
		}

        service { atomia-fsagent:
                name => atomia-fsagent,
                enable => true,
                ensure => running,
		hasstatus => false,
		pattern => "/usr/bin/nodejs /usr/lib/atomia-fsagent/main.js",
                subscribe => [ Package["atomia-fsagent"], File["/etc/default/fsagent"] ],
        }
		
		if $fs_agent_ssl {
			service { atomia-fsagent-ssl:
                name => atomia-fsagent-ssl,
                enable => true,
                ensure => running,
				subscribe => [ Package["atomia-fsagent"], File["/etc/default/fsagent-ssl"] ],
                require => [ Service["atomia-fsagent"] , File["/etc/init.d/atomia-fsagent-ssl"] ],
			}
		}
}

