class atomia::nagios::server(
    $username           = "nagios",
    $password           = "nagios"
) {

    # Install Nagios and plugins
    package { [
        'nagios-plugins-standard',
        'nagios-nrpe-plugin'
    ]:
        ensure => installed,
    }
    
     
    # Add Debian repo to get later version of Nagios
    apt::source { 'debian_stable':
        location          => 'http://ftp.se.debian.org/debian/',
        release           => 'wheezy',
        repos             => 'main',
        required_packages => 'debian-keyring debian-archive-keyring',
        pin               => '1000',
        include_src       => false,
        key               => '6FB2A1C265FFB764',
        key_server        => 'keyserver.ubuntu.com'
    }

    apt::force { 'nagios3':
      release => 'wheezy',
      require => Apt::Source['debian_stable'],
    }
    

    service { 'nagios3':
        ensure              => 'running',
        pattern             => '/usr/sbin/nagios3 -d /etc/nagios3/nagios.cfg',
        hasstatus           => false
    }
    
    file { "/etc/nagios3":
        owner  => root,
        group  => root,
        ensure => directory,
    }


    file { "/etc/nagios3/conf.d":
        ensure => directory,
        recurse => true,
        owner => "root",
        group => "root",
        mode => 0644,
    }
    
    file { "/etc/nagios3/conf.d/localhost_nagios2.cfg":
        ensure => absent
    }
    

    file { "/etc/nagios3/conf.d/hostgroups_nagios2.cfg.dpkg-dist":
        ensure => absent,
    }

    file { "/etc/nagios3/htpasswd.users":
        replace => no,
        owner   => root,
        group   => root,
        mode    => 444,
        content => generate("/usr/bin/htpasswd", "-bn", $username, $password),
        require => File["/etc/nagios3"]
        
    }
    
    # Configuration files
    file { '/etc/nagios3/cgi.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/cgi.cfg.erb'),
        require => File["/etc/nagios3"],
        notify  => Service["nagios3"]
    }  

    file { '/etc/nagios3/nagios.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/nagios.cfg.erb'),
        require => File["/etc/nagios3"],
        notify  => Service["nagios3"]
    }  
    
    file { '/etc/nagios3/commands.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/commands.cfg.erb'),
        require => File["/etc/nagios3"],
        notify  => Service["nagios3"]
    }  
    
    file { '/etc/nagios3/conf.d/hostgroups_nagios2.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/hostgroups_nagios2.cfg.erb'),
        require => File["/etc/nagios3/conf.d"],
        notify  => Service["nagios3"]
    }  
    

    file { '/etc/nagios3/conf.d/services_nagios2.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/services_nagios2.cfg.erb'),
        require => File["/etc/nagios3/conf.d"],
        notify  => Service["nagios3"]
    }  

    file { '/etc/nagios3/conf.d/extinfo_nagios2.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/extinfo_nagios2.cfg.erb'),
        require => File["/etc/nagios3/conf.d"],
        notify  => Service["nagios3"]
    }  
 
    file { '/etc/nagios3/conf.d/generic-service_nagios2.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/generic-service_nagios2.cfg.erb'),
        require => File["/etc/nagios3/conf.d"],
        notify  => Service["nagios3"]
    }   
 

    
    Nagios_service <<| |>>  
    Nagios_host <<| |>>

}


#TODO: 
