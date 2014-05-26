class atomia::phpmyadmin (
	$mysql_host
){
	package { phpmyadmin: ensure => present }
	package { apache2: ensure => present } 
	package { libapache2-mod-php5: ensure => present }
	 file { "/etc/phpmyadmin/config.inc.php":
                owner   => root,
                group   => root,
                mode    => 444,
		content => template('atomia/phpmyadmin/config.inc.php'),
                require => Package["phpmyadmin"],
        }

	
        file { "/etc/apache2/sites-available/phpmyadmin-default":
                owner   => root,
                group   => root,
                mode    => 444,
                source  => "puppet:///modules/atomia/phpmyadmin/default",
                require => Package["apache2"],
        }


        file { "/etc/apache2/sites-enabled/phpmyadmin-default":
                owner   => root,
                group   => root,
                mode    => 444,
                ensure => link,
                target => "/etc/apache2/sites-available/phpmyadmin-default",
                require => [File["/etc/apache2/sites-available/phpmyadmin-default"],
				Package["apache2"]],
                notify  => Service["apache2"],
        }


        if !defined(File['/etc/apache2/sites-enabled/000-default']) {
                file { "/etc/apache2/sites-enabled/000-default":
                        ensure  => absent,
                        require => Package["apache2"],
                        notify => Service["apache2"],
                }
        }

        if !defined(File['/etc/apache2/sites-available/default']) {
                file { "/etc/apache2/sites-available/default":
                        ensure  => absent,
                        require => Package["apache2"],
                        notify => Service["apache2"],
                }
        }

        file { "/etc/php5/apache2/php.ini":
               owner   => root,
               group   => root,
               mode    => 644,
	       source  => "puppet:///modules/atomia/phpmyadmin/php.ini",
               require => Package["apache2"],
               notify  => Service["apache2"],
        }

        exec { "force-reload-apache-phpmyadmin":
                refreshonly => true,
                before => Service["apache2"],
                command => "/etc/init.d/apache2 force-reload",
        }

        exec { "/usr/sbin/a2enmod php5":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/php5.load",
                require => Package["libapache2-mod-php5"],
                notify => Exec["force-reload-apache-phpmyadmin"],
        }

	service { 'apache2':
		ensure => running,
	}
}
