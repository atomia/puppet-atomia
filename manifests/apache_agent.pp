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

class atomia::apache_agent (
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
	$apache_modules_to_enable	= "rewrite,userdir,fcgid,suexec,expires,headers,deflate,include"
) {

	if $lsbdistrelease == "14.04" {
		$pa_conf_available_path = "/etc/apache2/conf-available"
		$pa_conf_file = "atomia-pa-apache.conf.ubuntu.1404"
		$pa_site = "000-default.conf"
		$pa_site_enabled = "000-default.conf"
	} else {
		$pa_conf_available_path = "/etc/apache2/conf.d"
		$pa_conf_file = "atomia-pa-apache.conf.ubuntu"
		$pa_site = "default"
		$pa_site_enabled = "000-default"
	}

	if $should_have_pa_apache == 1 {
		package { atomia-pa-apache:
			ensure	=> present,
			require	=> Package["apache2"],
		}
	}

	if !defined(Package['apache2']) {
		package { apache2: ensure => present }
	}

	$packages_to_install = [
		"atomiastatisticscopy", "libapache2-mod-fcgid-atomia", "apache2-suexec-custom-cgroups-atomia",
		"php5-cgi", "libexpat1", "cgroup-bin"
	]

	package { $packages_to_install: ensure => installed }

	$php_package_array = split($php_extension_packages, ',')
	package { $php_package_array: ensure => installed }
	
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
	 
	if $should_have_pa_apache == 1 {
		file { "/usr/local/apache-agent/settings.cfg":
			owner		=> root,
			group		=> root,
			mode		=> "440",
			content => template("atomia/apache_agent/settings.erb"),
			require => Package["atomia-pa-apache"],
		}
	}

	file { "${$pa_conf_available_path}/${$pa_conf_file}":
			ensure	=> present,
			content => template("atomia/apache_agent/atomia-pa-apache.conf.erb"),
			require => [Package["atomia-pa-apache"]],
			notify	=> Service["apache2"],
	}

	file { "/etc/statisticscopy.conf":
		owner	=> root,
		group	=> root,
		mode	=> "440",
		content	=> template("atomia/apache_agent/statisticscopy.erb"),
		require	=> Package["atomiastatisticscopy"],
	}

	file { "/var/log/httpd":
		owner	=> root,
		group	=> root,
		mode	=> "600",
		ensure	=> directory,
		before	=> Service["apache2"],
	}

	file { "/var/www/cgi-wrappers": mode => "755", }

	file { "$maps_path":
		owner	=> root,
		group	=> www-data,
		mode	=> "2750",
		ensure	=> directory,
		recurse => true,
	}

	file { "/storage/configuration/apache":
		owner	=> root,
		group	=> www-data,
		mode	=> "2750",
		ensure	=> directory,
		recurse	=> true,
	}

	$maps_to_ensure = [
		"$maps_path/frmrs.map", "$maps_path/parks.map", "$maps_path/phpvr.map", "$maps_path/redrs.map", "$maps_path/sspnd.map",
		"$maps_path/users.map", "$maps_path/vhost.map"
	]

	file { $maps_to_ensure:
		owner	=> root,
		group	=> www-data,
		mode	=> "440",
		ensure	=> present,
		require => File["$maps_path"],
	}


	if !defined(File["/etc/apache2/sites-enabled/${$pa_site_enabled}"]) {
		file { "/etc/apache2/sites-enabled/${$pa_site_enabled}":
			ensure	=> absent,
			require => Package["apache2"],
			notify	=> Service["apache2"],
		}
	}

	if !defined(File["/etc/apache2/sites-available/${$pa_site}"]) {
		file { "/etc/apache2/sites-available/${$pa_site}":
			ensure	=> absent,
			require	=> Package["apache2"],
			notify	=> Service["apache2"],
		}
	}

	file { "${$pa_conf_available_path}/001-custom-errors":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		source		=> "puppet:///modules/atomia/apache_agent/001-custom-errors",
		require		=> Package["apache2"],
		notify		=> Service["apache2"],
	}

	if $lsbdistrelease == "14.04" {
		file { "/etc/apache2/conf-enabled/001-custom-errors.conf":
		ensure	=> link,
		target	=> "../conf-available/001-custom-errors",
		require	=> File["${$pa_conf_available_path}/001-custom-errors"],
		notify	=> Service["apache2"],
		}
	}

	file { "/etc/apache2/suexec/www-data":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		source		=> "puppet:///modules/atomia/apache_agent/suexec-conf",
		require		=> [Package["apache2"], Package["apache2-suexec-custom-cgroups-atomia"]],
		notify	=> Service["apache2"],
	}

	file { "/etc/cgconfig.conf":
		owner	=> root,
		group	=> root,
		mode	=> "444",
		source	=> "puppet:///modules/atomia/apache_agent/cgconfig.conf",
		require	=> [Package["cgroup-bin"]],
	}

	file { "/storage/configuration/php_session_path":
		ensure	=> directory,
		owner	=> root,
		group	=> root,
		mode	=> "1733",
		require	=> Package["php5-cgi"],
	}

	file { "/storage/configuration/php.ini":
		replace	=> "no",
		ensure	=> present,
		source	=> "puppet:///modules/atomia/apache_agent/php.ini",
		owner	=> root,
		group	=> root,
		mode	=> "644",
	}

	file { "/etc/php5/cgi/php.ini":
		ensure	=> link,
		target	=> "/storage/configuration/php.ini",
		require	=> [File["/storage/configuration/php.ini"], Package["php5-cgi"]],
	}

	if $should_have_pa_apache == 1 {
		service { atomia-pa-apache:
			name		=> apache-agent,
			enable		=> true,
			ensure		=> running,
			hasstatus	=> false,
			pattern		=> "python /etc/init.d/apache-agent start",
			subscribe	=> [Package["atomia-pa-apache"], File["/usr/local/apache-agent/settings.cfg"]],
		}
	}
	
	
	$php_versions_array = split($php_versions, ',')
	arrayPHP { $php_versions_array: }
	
	if ($should_have_php_farm == 1) and ($lsbdistrelease == "14.04") {

		$phpcompilepackages = [ git, libxml2, libxml2-dev, libssl-dev, libcurl4-openssl-dev, pkg-config, libicu-dev, libmcrypt-dev, php5-dev, libgeoip-dev, libmagickwand-dev, libjpeg-dev, libpng12-dev, libmysqlclient-dev ]

		package { $phpcompilepackages:
			ensure	=> "installed",
			require	=> Package["libapache2-mod-fcgid-atomia"],
		}

		exec { "clone_phpfarm_repo" :
			command	=> "/usr/bin/git clone git://git.code.sf.net/p/phpfarm/code /opt/phpfarm",
			unless	=> "/usr/bin/test -f /opt/phpfarm/src/options.sh",
			require	=> [Package["libapache2-mod-fcgid-atomia"], Package["php5-dev"], Package["git"]],
		}

		file { "/opt/phpfarm/src/options.sh":
			owner	=> root,
			group	=> root,
			mode	=> "755",
			source	=> "puppet:///modules/atomia/apache_agent/php-options.sh",
			require	=> Exec["clone_phpfarm_repo"],
		}

		$php_branches_array = extract_major_minor($php_versions_array)

		file { "/etc/apache2/conf/phpversions.conf":
			owner	=> root,
			group	=> root,
			mode	=> "644",
			content	=> template("atomia/apache_agent/phpversions.erb"),
			require => [Package["atomia-pa-apache"]],
			notify	=> Service["apache2"],
		}
	}

	if !defined(Service['apache2']) {
		service { apache2:
			name	=> apache2,
			enable	=> true,
			ensure	=> running,
		}
	}

	if !defined(Exec['force-reload-apache']) {
		exec { "force-reload-apache":
			refreshonly	=> true,
			before		=> Service["apache2"],
			command		=> "/etc/init.d/apache2 force-reload",
		}
	}

	$apache_modules_to_enable_array = split($apache_modules_to_enable, ',')
	apacheModuleToEnable { $apache_modules_to_enable_array: }
}

define arrayPHP {
	$php_version = $name
	# Compile PHP and create wrappers 
	exec { "compile_php_${php_version}" :
		command	=> "/opt/phpfarm/src/compile.sh ${$php_version}",
		creates	=> "/opt/phpfarm/inst/bin/php-${$php_version}",
		timeout	=> 1800,
		onlyif	=> "/usr/bin/test -f /opt/phpfarm/src/options.sh",
		require	=> Package["libapache2-mod-fcgid-atomia"],
	}
	exec {"check_php_install_${php_version}":
		command	=> "/bin/sh -c '(/opt/phpfarm/inst/bin/php-${$php_version} --version | grep built) && touch /opt/phpfarm/inst/php-${$php_version}.tested'",
		creates	=> "/opt/phpfarm/inst/php-${$php_version}.tested",
		onlyif	=> "/usr/bin/test -f /opt/phpfarm/inst/bin/php-${$php_version}",
		require	=> Exec["compile_php_${php_version}"]
	}
	file { "/var/www/cgi-wrappers/php-fcgid-wrapper-${php_version}":
		owner		=> root,
		group		=> root,
		mode		=> "555",
		content		=> template("atomia/apache_agent/php-fcgid-wrapper-custom.erb"),
		require		=> [Exec["compile_php_${php_version}"], Exec["check_php_install_${php_version}"]],
	}
}

define apacheModuleToEnable {
	exec { "/usr/sbin/a2enmod $name":
		unless	=> "/usr/bin/test -f /etc/apache2/mods-enabled/$name.load",
		require	=> Package["apache2"],
		notify	=> Exec["force-reload-apache"],
	}
}
