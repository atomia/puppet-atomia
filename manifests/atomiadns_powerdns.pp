class atomia::atomiadns_powerdns (
	$ssl_enabled,
	$agent_user,
	$agent_password,
	$atomia_dns_url,
	$atomia_dns_ns_group
){

	if $atomia_linux_software_auto_update {
		package { atomiadns-powerdns-database: ensure => latest }
		package { atomiadns-powerdnssync: ensure => latest }
	} else {
		package { atomiadns-powerdns-database: ensure => present }
		package { atomiadns-powerdnssync: ensure => present }
	}

	package { pdns-static: ensure => present, require => [ Service["atomiadns-powerdnssync"] ] } 

	if $operatingsystem == "Debian" {
		package { dnsutils: ensure => present }
	}
	else {
		package { bind-utils: ensure => present }
	}

        service { atomiadns-powerdnssync:
                name => atomiadns-powerdnssync,
                ensure => running,
		pattern => ".*powerdnssync.*",
		require => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"], File["/etc/atomiadns.conf.powerdnssync"] ],
		subscribe => [ File["/etc/atomiadns.conf.powerdnssync"] ],
        }

	if $ssl_enabled == '1' {
                file { "/etc/atomiadns-mastercert.pem":
                        owner   => root,
                        group   => root,
                        mode    => 440,
			source => "puppet:///modules/atomia/atomiadns_powerdns/atomiadns_cert"
                }

		$atomiadns_conf = generate("/etc/puppet/modules/atomiadns_powerdns/files/generate_conf.sh", $agent_user, $agent_password, $fqdn, $atomia_dns_url, "ssl")
	} else {
		$atomiadns_conf = generate("/etc/puppet/modules/atomiadns_powerdns/files/generate_conf.sh", $agent_user, $agent_password, $fqdn, $atomia_dns_url, "nossl")
	}

	exec { "/usr/bin/atomiapowerdnssync add_server $atomia_dns_ns_group && /etc/init.d/atomiadns-powerdnssync stop && /etc/init.d/atomiadns-powerdnssync start && /usr/bin/atomiapowerdnssync full_reload_online":
		require => Package["atomiadns-powerdnssync"],
		unless => ["/usr/bin/atomiapowerdnssync get_server"],
	}
        file { "/etc/atomiadns.conf.powerdnssync":
                owner   => root,
                group   => root,
                mode    => 444,
                content => $atomiadns_conf,
                require => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"] ],
		notify => Exec["atomiadns_config_sync"],
        }
	if !defined(File["/usr/bin/atomiadns_config_sync"])
	{
        	file { "/usr/bin/atomiadns_config_sync":
                	owner   => root,
                	group   => root,
                	mode    => 500,
			source  => "puppet:///modules/atomiadns_powerdns/atomiadns_config_sync",
                	require => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"] ],
        	}
	        exec { "atomiadns_config_sync":
	                refreshonly => true,
        	        require => File["/usr/bin/atomiadns_config_sync"],
               	 	before => Service["atomiadns-powerdnssync"],
                	command => "/usr/bin/atomiadns_config_sync $ns_group",
        	}

	}

}

