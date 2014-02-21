class atomia::daggre (
	$global_auth_token,
	$ip_addr = $ipaddress, 
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
	
	file { "/etc/default/daggre":
		owner   => root,
		group   => root,
		mode    => 440,
		content =>  template("atomia/daggre/settings.cfg.erb"),
		require => Package["daggre"],		
	}
	
	file { "/etc/daggre_submit.conf":
		owner   => root,
		group   => root,
		mode    => 440,
		content => template("atomia/daggre/daggre_submit.conf.erb"),
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
