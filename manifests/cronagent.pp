## Cron agent

### Deploys and configures a server running the Atomia cron agent.

### Variable documentation
#### global_auth_token: The authentication token clients will use to access the API of the cron agent.
#### min_part: The lower part of the cron task cluster distribution range (0-1000) that this server handles.
#### max_part: The upper part of the cron task cluster distribution range (0-1000) that this server handles.
#### mail_host: The hostname or IP of the SMTP server to send mails through.
#### mail_port: The port of the SMTP server to send mails through.
#### mail_user: The username to authenticate as when connecting to the SMTP server used for sending mails.
#### mail_pass: The password to authenticate with when connecting to the SMTP server used for sending mails.
#### mail_from: The sender email to set for the mails sent by the cron service.
#### base_url: The base URL for the cron agent API.

### Validations
##### global_auth_token(advanced): %password
##### min_part(advanced): ^([0-9]{1,3}|1000)$
##### max_part(advanced): ^([0-9]{1,3}|1000)$
##### mail_host(advanced): %hostname
##### mail_port(advanced): ^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$
##### mail_user(advanced): ^[^[[:space:]]]+$
##### mail_pass(advanced): %password
##### base_url(advanced): %url

class atomia::cronagent (
	$global_auth_token, 
	$min_part = 0,  
	$max_part = 1000, 
	$mail_host = "localhost", 
	$mail_port = 25, 
	$mail_ssl = 0, 
	$mail_from = "", 
	$mail_user = "", 
	$mail_pass = "",
	$base_url  = "http://$fqdn:10101"
){
	
	include atomia::mongodb
	
	package { "atomia-cronagent": 
		ensure => present,
		require => Package["mongodb-10gen"]
	}

	if $mail_host == "localhost" or $mail_host == "127.0.0.1" {
		package { "postfix" :
			ensure => present,
		}
	}


	file { "/etc/default/cronagent":
		owner   => root,
		group   => root,
		mode    => "440",
		content => template("atomia/cronagent/settings.cfg.erb"),
		require => Package["atomia-cronagent"],		
	}
	
	service { "atomia-cronagent":
			name => atomia-cronagent,
			enable => true,
			ensure => running,
			hasstatus => false,
			pattern => "/usr/bin/(atomia-)?cronagent",
			require => [ Package["atomia-cronagent"], File["/etc/default/cronagent"] ],
			subscribe => File["/etc/default/cronagent"],
	}
}
