# == Class: domainreg
#
# This class is used to configure Atomia Domainreg
#
# === Parameters
#
# [*domainreg_service_url*]
#  (optional) Url for the domainreg_service. Defaults to 'http://localhost/domainreg'
#
# === Examples
#
# === Authors
#
# Stefan Mortensen <stefan.mortensen@atomia.com>
#
class atomia::domainreg (
        $service_url          		= "http://localhost/domainreg",
        $service_username     		= "domainreg",
        $service_password     		= "",
        $opensrs_user  			= "opensrs",
        $opensrs_pass  			= "",
        $opensrs_url   			= "https://horizon.opensrs.net:55443/",
        $opensrs_tlds  			= ["com","net","org","info"],
        $ssl_enabled            	= 0,
        $opensrs_only  			= 1,
	$linux_software_auto_update 	= 0
){

        if $linux_software_auto_update {
                package { atomiadomainregistration-masterserver: ensure => latest }
                package { atomiadomainregistration-client: ensure => latest }
        } else {
                package { atomiadomainregistration-masterserver: ensure => present }
                package { atomiadomainregistration-client: ensure => present }
        }

        package { procmail: ensure => latest }

        if $ssl_enabled == 1 {
                #include apache_wildcard_ssl
        }

        if $opensrs_only == 1
        {

                file { "domainreg.conf.puppet":
                        path    => "/etc/domainreg.conf.puppet",
                        owner   => root,
                        group   => root,
                        mode    => 444,
                        content => template('atomia/domainreg.conf.puppet'),
                        require => [ Package["atomiadomainregistration-masterserver"], Package["atomiadomainregistration-client"] ],
                        notify => Exec["domainreg.conf puppetmerge"],
                }

                exec { "domainreg.conf puppetmerge":
                        command => "/usr/bin/awk 'FILENAME == \"/etc/domainreg.conf\" && !/^db_/ { next } { print }' /etc/domainreg.conf /etc/domainreg.conf.puppet > /tmp/domainreg.conf.puppetmerge && mv /tmp/domainreg.conf.puppetmerge /etc/domainreg.conf",
                        onlyif => "/usr/bin/test -f /etc/domainreg.conf && test -f /etc/domainreg.conf.puppet",
                        refreshonly => true,
                        notify => Service["atomiadomainregistration-api"],
                }

                service { atomiadomainregistration-api:
                        name => atomiadomainregistration-api,
                        enable => true,
                        ensure => running,
                        pattern => ".*/usr/bin/domainregistration.*",
                        require => [ Package["atomiadomainregistration-masterserver"], Package["atomiadomainregistration-client"], File["/etc/domainreg.conf.puppet"] ],
                }
        }

        if !defined(Class['atomia::apache_password_protect']) {
                class {
                        'atomia::apache_password_protect':
                                username => $service_username,
                                password => $service_password
                }
        }

        service { apache2:
                name => apache2,
                enable => true,
                ensure => running,
        }

    file { '/etc/cron.d/rotate-domainreg-logs':
        ensure  => present,
        content => "0 0 * * * root lockfile -r0 /var/run/rotate-domainreg-logs && (find /var/log/atomiadomainregistration -mtime +14 -exec rm -f '{}' '+'; rm -f /var/run/rotate-domainreg-logs.lock)",
    }
}

