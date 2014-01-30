class atomia::apache_password_protect ($application_protect) {

        if $application_protect == "atomiadns" {
                $htconf_dns = generate("/usr/bin/htpasswd", "-bn", $atomia_dns_agent_user, $atomia_dns_agent_password)
        }
        if $application_protect == "domainreg" {
                $htconf_domain = generate("/usr/bin/htpasswd", "-bn", $domainreg_service_username, $domainreg_service_password)
        }
        if $application_protect == "webinstaller" {
                $htconf_webinst = generate("/usr/bin/htpasswd", "-bn", $webinstaller_username, $webinstaller_password)
        }

        $htconf = "${htconf_dns}${htconf_domain}${htconf_webinst}"

        file { "/etc/apache2":
                ensure => directory,
                owner   => root,
                group   => root,
                mode    => 755,
        }

        file { "/etc/apache2/conf.d":
                ensure => directory,
                owner   => root,
                group   => root,
                mode    => 755,
                require => File["/etc/apache2"],
        }


        file { "/etc/apache2/htpasswd.conf":
                replace => no,
                owner   => root,
                group   => root,
                mode    => 444,
                content => $htconf,
                require => File["/etc/apache2"],
        }

        file { "/etc/apache2/conf.d/passwordprotect":
                owner   => root,
                group   => root,
                mode    => 440,
                source  => "puppet:///modules/apache_password_protect/passwordprotect",
                require => File["/etc/apache2/conf.d"],
        }
}

