class atomia::haproxy(
	$agent_user = "haproxy",
	$agent_password
	) {
	
	if $atomia_linux_software_auto_update {
		package { atomia-pa-haproxy: 
			ensure => latest,
		}
	} else {
		package { atomia-pa-haproxy: 
			ensure => present,
		}
	}

	$haproxy_conf = generate("/etc/puppet/modules/atomia/files/haproxy/atomia-pa-haproxy.conf.sh", $agent_user,$agent_password)

	file { "/etc/atomia-pa-haproxy.conf":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $haproxy_conf,
		require => Package["atomia-pa-haproxy"],
		notify => Service["atomia-pa-haproxy"],
	}
	
	file { "/etc/haproxy/haproxy.cfg":
		require => Package["atomia-pa-haproxy"],
		notify => Exec["restart-haproxy"],
	}
	
	exec { clear-haproxy-conf:
		path        => ["/usr/bin", "/usr/sbin"],
		onlyif 		=> "[ x`md5sum /etc/haproxy/haproxy.cfg | cut -d ' ' -f 1` = x`grep haproxy.cfg /var/lib/dpkg/info/haproxy.md5sums | cut -d ' ' -f 1` ]",
		command 	=> "echo '' > /etc/haproxy/haproxy.cfg",
		provider    => "shell"
	}
	
	file { "/etc/default/haproxy":
		source => "puppet:///modules/atomia/haproxy/haproxy-default",  
		require => Package["atomia-pa-haproxy"],
		notify => Exec["restart-haproxy"],
	}
	
	if !defined(Exec['restart-haproxy']) {
	        exec { "restart-haproxy":
			refreshonly => true,
			command => "/etc/init.d/haproxy restart",
		}
	}

	service { "atomia-pa-haproxy" :
		name => atomia-pa-haproxy,
		enable => true,
		ensure => running,
		pattern => ".*/usr/bin/atomia-pa-haproxy",
		require => Package["atomia-pa-haproxy"],
		subscribe => File["/etc/atomia-pa-haproxy.conf"]
	}
}
