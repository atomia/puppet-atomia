## Atomia Domain Registration

### Deploys and configures a server running Atomia Domain Registration.

### Variable documentation
#### service_url: The URL of the Atomia Domain Registration service.
#### service_username: The username to require for accessing the service.
#### service_password: The password to require for accessing the service.
#### db_hostname: The hostname of the Atomia Domain Registration database.
#### db_username: The username for the Atomia Domain Registration database.
#### db_password: The password for the Atomia Domain Registration database.
#### domainreg_global_config: The global section of the /etc/domainreg.conf file.
#### domainreg_tld_config_hash: The TLD configuration sections for all the Atomia Domain Registration TLD processes.

### Validations
##### service_url(advanced): %url
##### service_username(advanced): ^[a-z]+$
##### service_password(advanced): %password
##### db_hostname(advanced): ^[a-z0-9_][a-z0-9._-]*$
##### db_username(advanced): ^[a-z]+$
##### db_password(advanced): %password
##### domainreg_global_config(advanced,default_file=domainreg_global_default.conf): %domainreg_global_config
##### domainreg_tld_config_hash: %domainreg_tld_config_hash

class atomia::domainreg (
	$service_url	  		= "http://$fqdn/domainreg",
	$service_username     		= "domainreg",
	$service_password     		= "",
	$db_hostname			= "127.0.0.1",
	$db_username			= "domainreg",
	$db_password			= "",
	$domainreg_global_config	= "",
	$domainreg_tld_config_hash	= {}
){

	$domainreg_global_config_default = file("atomia/domainreg/domainreg_global_default.conf")

	package { atomiadomainregistration-masterserver:
		ensure => present,
		require => [ File["/etc/domainreg.conf"] ]
	}

	package { atomiadomainregistration-client: ensure => present }

	package { procmail: ensure => present }


	file { "/etc/domainreg.conf":
		path    => "/etc/domainreg.conf",
		owner   => root,
		group   => root,
		mode    => 444,
		content => template('atomia/domainreg/domainreg.conf'),
		notify => [ Service["atomiadomainregistration-api"], Service["apache2"] ]
	}

	service { atomiadomainregistration-api:
		name => atomiadomainregistration-api,
		enable => true,
		ensure => running,
		pattern => ".*/usr/bin/domainregistration.*",
		require => [ Package["atomiadomainregistration-masterserver"], Package["atomiadomainregistration-client"], File["/etc/domainreg.conf"] ],
	}

	if !defined(Class['atomia::apache_password_protect']) {
		class { 'atomia::apache_password_protect':
			username => $service_username,
			password => $service_password
		}
	}

	service { apache2:
		name => apache2,
		enable => true,
		ensure => running,
		require => Package['atomiadomainregistration-masterserver'],
	}

	file { '/etc/cron.d/rotate-domainreg-logs':
		ensure  => present,
		content => "0 0 * * * root lockfile -r0 /var/run/rotate-domainreg-logs && (find /var/log/atomiadomainregistration -mtime +14 -exec rm -f '{}' '+'; rm -f /var/run/rotate-domainreg-logs.lock)",
    }
}

