## Atomia apache agent

### Deploys and configures an apache webserver cluster node with the atomia apache agent.

### Variable documentation
#### username: The username to require when accessing the apache agent.
#### password: The password to require when accessing the apache agent.
#### atomia_clustered: Defines if this is a clustered instance or not.
#### should_have_pa_apache: Defines if this node should have a copy of the apache agent installed or not.
#### content_share_nfs_location: The location of the NFS share for customer website content.
#### config_share_nfs_location: The location of the NFS share for web cluster configuration.
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### cluster_ip: The virtual IP of the apache cluster.
#### apache_agent_ip: The IP or hostname of the apache agent used by Automation Server to provision apache websites.
#### maps_path: The pathw here the apache website and user maps are stored.
#### should_have_php_farm: Toggles if we are to build and install a set of custom PHP versions or use the distribution default.
#### php_versions: If using custom PHP versions, then this is a comma separated list of the versions to compile and install.
#### php_extension_packages: Determines which PHP extensions to install (comma separated list of package names).
#### apache_modules_to_enable: Determines which Apache modules to enable (comma separated list of modules).

### Validations
##### username(advanced): %username
##### password(advanced): %password
##### atomia_clustered(advanced): %int_boolean
##### should_have_pa_apache(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %int_boolean
##### cluster_ip: %ip
##### apache_agent_ip(advanced): %ip_or_hostname
##### maps_path(advanced): %path
##### should_have_php_farm(advanced): %int_boolean
##### php_versions(advanced): ^[0-9]+\.[0-9]+\.[0-9]+(,[0-9]+\.[0-9]+\.[0-9]+)*$
##### php_extension_packages(advanced): ^.*$
##### apache_modules_to_enable(advanced): ^[a-z0-9_-]+(,[a-z0-9_-]+)$

class atomia::apache_agent_cl (
	$username			= "automationserver",
	$password,
	$atomia_clustered		= 1,
	$should_have_pa_apache		= 1,
	$content_share_nfs_location	= '',
	$config_share_nfs_location	= '',
	$use_nfs3			= 1,
	$cluster_ip,
	$apache_agent_ip		= $fqdn,
	$maps_path			= "/storage/configuration/maps",
	$should_have_php_farm		= 0,
	$php_versions			= "5.4.45,5.5.29,5.6.10",
	$php_extension_packages		= "php5-gd,php5-imagick,php5-sybase,php5-mysql,php5-odbc,php5-curl,php5-pgsql",
	$apache_modules_to_enable	= "rewrite,userdir,fcgid,suexec,expires,headers,deflate,include",
    $is_master  = 1
) {


    $pa_conf_available_path = "/etc/apache2/conf-available"
    $pa_conf_file = "atomia-pa-apache.conf.ubuntu.1404"
    $pa_site = "000-default.conf"
    $pa_site_enabled = "000-default.conf"

	if $content_share_nfs_location == '' {
		$internal_zone = hiera('atomia::internaldns::zone_name','')
		
		package { 'glusterfs-client': ensure => present, }
		
		if !defined(File["/storage"]) {
			file { "/storage":
			ensure => directory,
			}
		}
		
		fstab::mount { '/storage/content':
			ensure  => 'mounted',
			device  => "gluster.${internal_zone}:/web_volume",
			options => 'defaults,_netdev',
			fstype  => 'glusterfs',
			require => [Package['glusterfs-client'],File["/storage"]],
		}	
		fstab::mount { '/storage/configuration':
			ensure  => 'mounted',
			device  => "gluster.${internal_zone}:/config_volume",
			options => 'defaults,_netdev',
			fstype  => 'glusterfs',
			require => [ Package['glusterfs-client'],File["/storage"]],
		}			
	}
	else
	{
		atomia::nfsmount { 'mount_content':
			use_nfs3		 => 1,
			mount_point  => '/storage/content',
			nfs_location => $content_share_nfs_location
		}

		atomia::nfsmount { 'mount_configuration':
			use_nfs3		 => 1,
			mount_point  => '/storage/configuration',
			nfs_location => $config_share_nfs_location
		}
	}


	if $should_have_pa_apache == "1" {
		package { atomia-pa-apache:
			ensure	=> present,
			require	=> [Package["httpd"], Package["cronolog"], Package["atomia-python-ZSI"], Package["mod_ssl"] ],
		}
	}

    exec { 'add epel repo':
        command => '/usr/bin/rpm -Uhv http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm',
        unless => "/usr/bin/rpm -qi epel-release | /bin/grep  -c 'Build Date'"
    }    
        
    $packages_to_install = [
        "atomiastatisticscopy", "httpd", "cronolog", "atomia-python-ZSI", "mod_ssl"
    ]        

	package { $packages_to_install: ensure => installed }
    
    service { 'httpd':
        ensure  => running,
    }
    # Install Cagefs
    package { cagefs:
        ensure => present,
        notify => Exec['init cagefs']
    }
    
    exec { 'init cagefs':
        command => '/usr/sbin/cagefsctl --init',
        require => Package['cagefs'],
        refreshonly => true,
        notify  => Exec['enable cagefs']
    }
    
    exec { 'enable cagefs':
        command => '/usr/sbin/cagefsctl --disable-all',
        require => Package['cagefs'],
        refreshonly => true
    }
    
    # Install alt-php
    package { 'lvemanager': ensure => installed }
    
    exec { 'install altphp':
        command => '/usr/bin/yum -y groupinstall alt-php',
        timeout     => 1800,
        unless => '/usr/bin/rpm -qa | /bin/grep -c alt-php',
        require => Package['lvemanager'],
    }
    
    # Install mod_lsapi
    exec { 'install mod_lsapi':
        command => "/usr/bin/yum -y install liblsapi liblsapi-devel mod_lsapi gcc gcc-c++ cmake httpd-devel --enablerepo=cloudlinux-updates-testing",
        unless => '/usr/bin/rpm -qa | /bin/grep -c liblsapi',
        notify => Exec['setup mod_lsapi']
    }
    
    exec { 'setup mod_lsapi':
        command => "/usr/bin/switch_mod_lsapi --setup",
        refreshonly => true
    }
    
    file { "/etc/httpd/conf.d/lsapi.conf":
        owner		=> root,
        group		=> root,
        mode		=> "0644",
        content => template("atomia/apache_agent/lsapi.conf.erb"),
        require => Exec['install mod_lsapi'],
        notify  => Service['httpd']
    }
    
   # Install mod_hostinglimits
   package { 'mod_hostinglimits' :
        ensure => present,
        require => Package['httpd']
   }
   
    file { "/etc/httpd/conf.d/modhostinglimits.conf":
        owner		=> root,
        group		=> root,
        mode		=> "0644",
        content => template("atomia/apache_agent/modhostinglimits.conf.erb"),
        require => Package['mod_hostinglimits'],
        notify  => Service['httpd']
    }
    
    # CloudLinux shared configuration
    file { '/storage/configuration/cloudlinux':
        owner   => root,
        group   => root,
        mode    => '0701',
        ensure  => directory,
    }

    file { '/storage/configuration/cloudlinux/users.enabled':
        owner   => root,
        group   => root,
        mode    => '0701',
        ensure  => directory,
        require => File['/storage/configuration/cloudlinux']
    }   
   
    file { '/etc/cagefs/users.enabled':
        ensure => 'link',
        target => '/storage/configuration/cloudlinux/users.enabled',
        require => File['/storage/configuration/cloudlinux']
    }
    
    file { '/storage/configuration/cloudlinux/cagefs_var':
        owner   => root,
        group   => root,
        mode    => '0751',
        ensure  => directory,
        require => File['/storage/configuration/cloudlinux']
    }       

    file { '/var/cagefs':
        ensure => 'link',
        target => '/storage/configuration/cloudlinux/cagefs_var',
        require => [File['/storage/configuration/cloudlinux/cagefs_var'], Exec['init cagefs']] 
    }    
    
    file { '/storage/configuration/cloudlinux/cagefs_container':
        owner   => root,
        group   => root,
        mode    => '0755',
        ensure  => directory,
        require => File['/storage/configuration/cloudlinux']
    }
    
    file { '/etc/container':
        ensure  => 'link',
        target  => '/storage/configuration/cloudlinux/cagefs_container',
        require => [File['/storage/configuration/cloudlinux/cagefs_container'], Exec['init cagefs']]
    }
    
    file { '/storage/configuration/cloudlinux/cagefs_container/ve.cfg':
        owner   => root,
        group   => root,
        mode    => '0644',
        ensure  => file,
        replace => 'no',
        content => template("atomia/apache_agent/ve.cfg.erb"),
        require => File['/etc/container']
    }    
    
}
