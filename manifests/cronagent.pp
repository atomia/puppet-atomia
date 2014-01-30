class atomia::cronagent (

	$global_auth_token, 
	$min_part = 0,  
	$max_part = 1000, 
	$mail_host = "", 
	$mail_port = 25, 
	$mail_ssl = 0, 
	$mail_from = "", 
	$mail_user = "", 
	$mail_pass = ""

){
	
	include atomia::mongodb
	
	package { "atomia-cronagent": 
		ensure => present,
		require => Package["mongodb-10gen"]
	}
	
	package { "postfix" :
		ensure => present,
	}

	
	$settings_content = generate("/etc/puppet/modules/cronagent/files/settings.cfg.sh", $global_auth_token, $min_part, $max_part, $mail_host, $mail_port, $mail_ssl, $mail_from, "$mail_user", "$mail_pass")
	file { "/etc/default/cronagent":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $settings_content,
		require => Package["atomia-cronagent"],		
	}
	
	service { "atomia-cronagent":
			name => atomia-cronagent,
			enable => true,
			ensure => running,
			pattern => ".*/usr/bin/cronagent.*",
			require => [ Package["atomia-cronagent"], File["/etc/default/cronagent"] ],
			subscribe => File["/etc/default/cronagent"],
	}
				
}
