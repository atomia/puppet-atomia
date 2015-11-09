## Atomia DNS PowerDNS agent

### Deploys and configures a nameserver running the Atomia DNS PowerDNS agent.

### Variable documentation
#### atomia_dns_url: The URL of the Atomia DNS API service.
#### agent_user: The username to require for accessing the service.
#### agent_password: The password to require for accessing the service.
#### db_hostname: The hostname of the Atomia Domain Registration database.
#### db_username: The username for the Atomia Domain Registration database.
#### db_password: The password for the Atomia Domain Registration database.
#### ns_group: The Atomia DNS nameserver group used for the zones in your environment.
#### atomia_dns_extra_config: Extra config to append to /etc/atomiadns.conf as-is.

### Validations
##### atomia_dns_url(advanced): %url
##### agent_user(advanced): %username
##### agent_password(advanced): %password
##### db_hostname(advanced): %hostname
##### db_username(advanced): %username
##### db_password(advanced): %password
##### ns_group(advanced): ^[a-z0-9_-]+$
##### atomia_dns_extra_config(advanced): .*

class atomia::atomiadns_powerdns (
	$atomia_dns_url	= "http://$fqdn/atomiadns",
	$agent_user	= "atomiadns",
	$agent_password	= "",
	$db_hostname	= "127.0.0.1",
	$db_username	= "powerdns",
	$db_password	= "",
	$ns_group	= "default",
	$atomia_dns_extra_config = ""
) {
  
	if !in_atomia_role("atomiadns") {
		file { "/etc/atomiadns.conf":
			owner   => root,
			group   => root,
			mode    => "444",
			content => template("atomia/atomiadns_powerdns/atomiadns.conf.erb"),
			notify => [ Service["atomiadns-powerdnssync"] ],
		}
	}

	if $lsbdistrelease == "14.04" { 
		$pdns_package = "pdns-server"

		package { pdns-backend-mysql:
			ensure => present,
			require => [ Package[$pdns_package] ]
		}
	} else {
		$pdns_package = "pdns-static"
	}

	package { $pdns_package:
		ensure  => present
	}

	service { pdns:
		ensure    => running,
		require   => [ Package[$pdns_package] ]
	}

	package { atomiadns-powerdns-database:
		require => [ File["/etc/atomiadns.conf"], Package[$pdns_package] ],
		notify => [ Service["pdns"] ]
	}

	package { atomiadns-powerdnssync:
  		ensure => present,
		require => [ Package["atomiadns-powerdns-database"] ]
	}

	if $operatingsystem == "Ubuntu" {
		package { dnsutils: ensure => present }
	} else {
		package { bind-utils: ensure => present }
	}

	service { atomiadns-powerdnssync:
		name      => atomiadns-powerdnssync,
		ensure    => running,
		pattern   => ".*powerdnssync.*",
		require   => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"] ],
	}

	if !in_atomia_role("atomiadns") {
		exec { "add-server":
			command => "/usr/bin/atomiapowerdnssync add_server \"$ns_group\" && /etc/init.d/atomiadns-powerdnssync stop && /etc/init.d/atomiadns-powerdnssync start && /usr/bin/atomiapowerdnssync full_reload_online",
			require => [ Package["atomiadns-powerdnssync"] ],
			unless  => ["/usr/bin/atomiapowerdnssync get_server"],
		}
	} else {
		exec { "add-server":
			command => "/usr/bin/atomiapowerdnssync add_server \"$ns_group\" && /etc/init.d/atomiadns-powerdnssync stop && /etc/init.d/atomiadns-powerdnssync start && /usr/bin/atomiapowerdnssync full_reload_online",
			require => [ Package["atomiadns-powerdnssync"], Exec["add_nameserver_group"] ],
			unless  => ["/usr/bin/atomiapowerdnssync get_server"],
		}
	}
}
