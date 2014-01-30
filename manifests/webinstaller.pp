class atomia::webinstaller (
	$agent_username 		= "webinstaller",
	$agent_password      = "",
	) {
	if $atomia_linux_software_auto_update {
		package { atomiawebinstaller-api: ensure => latest }
		package { atomiawebinstaller-atomiachannel: ensure => latest }
		package { atomiawebinstaller-database: ensure => latest }
		package { atomiawebinstaller-masterserver: ensure => latest }
		if !defined(Package['atomiawebinstaller-client']) {
			package { atomiawebinstaller-client: ensure => latest }
		}
	} else {
		package { atomiawebinstaller-api: ensure => present }
		package { atomiawebinstaller-atomiachannel: ensure => present }
		package { atomiawebinstaller-database: ensure => present }
		package { atomiawebinstaller-masterserver: ensure => present }
		if !defined(Package['atomiawebinstaller-client']) {
			package { atomiawebinstaller-client: ensure => present }
		}
	}
        if $ssl_enabled {
                include apache_wildcard_ssl
        }

        class {
                'atomia::apache_password_protect':
                username => $agent_username,
                password => $agent_password
        }
	service { 'apache': 
		name => apache2,
		ensure => running
	}

}

