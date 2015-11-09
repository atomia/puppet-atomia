## Atomia DNS

### Deploys and configures a server running the Atomia DNS API.

### Variable documentation
#### atomia_dns_url: The URL of the Atomia DNS API service.
#### nameserver1: The name of your primary nameserver (used in SOA for default zones created).
#### registry: 
#### nameservers: A comman separated list of your nameservers (used as NS for default zones created).
#### agent_user: The username to require for accessing the service.
#### agent_password: The password to require for accessing the service.
#### db_hostname: The hostname of the Atomia Domain Registration database.
#### db_username: The username for the Atomia Domain Registration database.
#### db_password: The password for the Atomia Domain Registration database.
#### ns_group: The Atomia DNS nameserver group used for the zones in your environment.
#### zones_to_add: A newline delimited list of default zones to add after setup.
#### atomia_dns_extra_config: Extra config to append to /etc/atomiadns.conf as-is.

### Validations
##### atomia_dns_url(advanced): %url
##### nameserver1(advanced): %hostname
##### registry(advanced): %hostname
##### nameservers(advanced): ^\[([a-z0-9.-]+,)*[a-z0-9.-]+\]$
##### agent_user(advanced): %username
##### agent_password(advanced): %password
##### db_hostname(advanced): %hostname
##### db_username(advanced): %username
##### db_password(advanced): %password
##### ns_group(advanced): ^[a-z0-9_-]+$
##### zones_to_add(advanced): ^([a-z0-9.-]+,)*[a-z0-9.-]+$
##### atomia_dns_extra_config(advanced): .*

class atomia::atomiadns (
	$atomia_dns_url	= "http://$fqdn/atomiadns",
	$nameserver1	= expand_default('ns1.[[atomia_domain]].'),
	$registry	= expand_default('registry.[[atomia_domain]].'),
	$nameservers	= expand_default('[ ns1.[[atomia_domain]], ns2.[[atomia_domain]] ]'),
	$agent_user	= "atomiadns",
	$agent_password	= "",
	$db_hostname	= "127.0.0.1",
	$db_username	= "domainreg",
	$db_password	= "",
	$ns_group	= "default",
	$zones_to_add	= expand_default('preview.[[atomia_domain]],mysql.[[atomia_domain]],mssql.[[atomia_domain]],cloud.[[atomia_domain]],postgresql.[[atomia_domain]]'),
	$atomia_dns_extra_config = ""
) {
    
	package { atomiadns-masterserver:
		ensure => present,
		require => [ File["/etc/atomiadns.conf"] ]
	}
  
	if !defined(Package['atomiadns-client']) {
		package { atomiadns-client: ensure => latest }
	}

	if !defined(Class['atomia::apache_password_protect']) {
		class { 'atomia::apache_password_protect':
			username => $agent_user,
			password => $agent_password,
			require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
		}
	}

	service { apache2:
		ensure => running,
		require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
	}

	exec { add_nameserver_group:
		require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
		unless  => "/usr/bin/sudo -u postgres psql zonedata -tA -c \"SELECT name FROM nameserver_group WHERE name = '$ns_group'\" | grep '^$ns_group\$'",
		command => "/usr/bin/sudo -u postgres psql zonedata -c \"INSERT INTO nameserver_group (name) VALUES ('$ns_group')\"",
	}


	file { "/etc/atomiadns.conf":
		owner   => root,
		group   => root,
		mode    => "444",
		content => template("atomia/atomiadns/atomiadns.erb"),
		notify => Service["apache2"]
	}


	if $zones_to_add {
		file { "/usr/share/doc/atomiadns-masterserver/zones_to_add.txt":
			owner   => root,
			group   => root,
			mode    => "500",
			content => $zones_to_add,
			require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
			notify  => Exec['remove_lock_file'],
		}

		exec { "remove_lock_file":
			command     => "/bin/rm -f /usr/share/doc/atomiadns-masterserver/sync_zones_done*.txt",
			refreshonly => true,
		}

		file { "/usr/share/doc/atomiadns-masterserver/add_zones.sh":
			owner   => root,
			group   => root,
			mode    => "500",
			source  => "puppet:///modules/atomia/atomiadns/add_zones.sh",
			require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
		}

		exec { "atomiadns_add_zones":
			require => [ File["/usr/share/doc/atomiadns-masterserver/zones_to_add.txt"], File['/usr/share/doc/atomiadns-masterserver/add_zones.sh'], Package['atomiadns-client'], Exec['add_nameserver_group'] ],
			command => "/bin/sh /usr/share/doc/atomiadns-masterserver/add_zones.sh \"$ns_group\" \"$nameserver1\" \"$nameservers\" \"$registry\"",
			unless  => "/usr/bin/test -f /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt",
		}
	}
}

