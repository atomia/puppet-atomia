class atomia::daggre (
	$global_auth_token,
	$ip_addr, 
	) {
	
	include atomia::mongodb
	
	if $atomia_linux_software_auto_update {
		package { "daggre": 
			ensure => latest,
			require => Package["mongodb-10gen"]
		}
		package { "atomia-daggre-reporters-disk": 
			ensure => latest,
			require => Package["daggre"]
		}
		package { "atomia-daggre-reporters-weblog": 
			ensure => latest,
			require => Package["daggre"]
		}
	} else {
		package { "daggre": 
			ensure => present,
			require => Package["mongodb-10gen"]
		}
		package { "atomia-daggre-reporters-disk": 
			ensure => present,
			require => Package["daggre"]
		}
		package { "atomia-daggre-reporters-weblog": 
			ensure => present,
			require => Package["daggre"]
		}
	}
	
	$settings_content = generate("/etc/puppet/modules/atomia/files/daggre/settings.cfg.sh", $global_auth_token)
	file { "/etc/default/daggre":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $settings_content,
		require => Package["daggre"],		
	}
	
	$daggre_submit_content = generate("/etc/puppet/modules/atomia/files/daggre/daggre_submit.conf.sh", $global_auth_token, $ip_addr)
	file { "/etc/daggre_submit.conf":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $daggre_submit_content,
		require => Package["atomia-daggre-reporters-disk", "atomia-daggre-reporters-weblog"],		
	}	
	
	service { "daggre":
			name => daggre,
			enable => true,
			ensure => running,
			pattern => ".*/usr/bin/daggre.*",
			require => [ Package["daggre"], File["/etc/default/daggre"] ],
			subscribe => File["/etc/default/daggre"],
	}
				
}
