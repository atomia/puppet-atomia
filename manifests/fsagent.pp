class atomia::fsagent(
	$fs_agent_user,
	$fs_agent_password,
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

        file { "/storage/content/backup":
            	ensure => "directory",
                owner   => root,
                group   => root,
                mode    => 710,
       }


        $settings_content = generate("/etc/puppet/modules/fsagent/files/settings.cfg.sh", $fs_agent_user, $fs_agent_password)
        file { "/etc/default/fsagent":
                owner   => root,
                group   => root,
                mode    => 440,
                content => $settings_content,
                require => [ Package["atomia-fsagent"], File["/storage/content/backup"] ],
        }

		if $fs_agent_ssl {
			$settings_ssl_content = generate("/etc/puppet/modules/fsagent/files/settings-ssl.cfg.sh", $fs_agent_user, $fs_agent_password)
			$init_file = generate("/etc/puppet/modules/fsagent/files/atomia-fsagent-ssl.sh")
			
			file { "/etc/default/fsagent-ssl":
                owner   => root,
                group   => root,
                mode    => 440,
				ensure  => present,
                content => $settings_ssl_content,
                require => [ Package["atomia-fsagent"] ],
			}
			
			file { "/etc/init.d/atomia-fsagent-ssl":
                owner   => root,
                group   => root,
                mode    => 755,
				ensure  => present,
                content => $init_file,
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

