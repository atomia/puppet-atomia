#
# == Class: atomia::apache_agent
#
# Manifest to install/configure Atomia Apache agent
#
# [password]
# Define a password for accessing the agent
# (required)
#
# [content_share_nfs_location]
# Define where the content nfs share is located
# (required)
#
# [config_share_nfs_location]
# Define where the config nfs share is located
# (required)
#
# [$username]
# Defines the username for accessing the agent
# (optional) Defaults to apacheagent
#
# [ssl_enabled]
# Defines if ssl should be used or not
# (optional) Defaults to false
#
# [atomia_clustered]
# Defines if this is a clustered instance
# (optional) Defaults to true
#
# [should_have_pa_apache]
# Defines if the apache agent shall be debloyed or not
# (optional) Defaults to true
#
#
# === Examples
#
# class {'atomia::apache_agent':
#   password                      => 'myPassword',
#   content_share_nfs_location    => 'storage.atomia.com:/storage/content'
#   config_share_nfs_location     => 'storage.atomia.com:/storage/configuration'
#}

class atomia::apache_agent (
  # Required password
  $password,
  # Enable ssl if needed
  $ssl_enabled           = 0,
  # Set if this node is part of a cluster
  $atomia_clustered      = 1,
  # Username for the agent
  $username              = "apacheagent",
  # Omit the provisioning agent
  $should_have_pa_apache = 1,
  # Content share nfs location
  $content_share_nfs_location,
  # Config share nfs location
  $config_share_nfs_location,
  $use_nfs3 = 1,
  $cluster_ip = "",
  $apache_agent_ip = $ipaddress,
  $maps_path = "/storage/configuration/maps",
  # Set this property to 0 if you don't want to have PHP selector feature
  $should_have_php_farm = 0,
  # Set php_version_XX property to desired PHP version
  $php_versions = ['5.4.45','5.5.29','5.6.10'],
  ) {

  if $lsbdistrelease == "14.04" {
    $pa_conf_available_path = "/etc/apache2/conf-available"
    $pa_conf_file = "atomia-pa-apache.conf"
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
      ensure => present,
      require => Package["apache2"],
    }
  }

  package { atomiastatisticscopy: ensure => present }

  if !defined(Package['apache2']) {
    package { apache2: ensure => present }
  }

  package { libapache2-mod-fcgid-atomia: ensure => present }

  package { apache2-suexec-custom-cgroups-atomia: ensure => present }

  package { php5-cgi: ensure => present }

  package { libexpat1: ensure => present }

  package { cgroup-bin: ensure => present }

  # PHP extensions except for default
  package { php5-gd: ensure => installed }

  package { php5-imagick: ensure => installed }

  package { php5-sybase: ensure => installed }

  package { php5-mysql: ensure => installed }

  package { php5-odbc: ensure => installed }

  package { php5-curl: ensure => installed }

  package { php5-pgsql: ensure => installed }

  # SSL support
  if $ssl_enabled != 0 {
    $ssl_generate_var = "ssl"

    class { 'openssl': }

    ssl_pkey { '/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.key': ensure => 'present' }

    x509_cert { '/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.crt':
      ensure      => 'present',
      private_key => '/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.key',
      days        => 4536,
      force       => false,
    }

    file { "/usr/local/apache-agent/wildcard.key":
      owner   => root,
      group   => root,
      mode    => 440,
      content => "puppet:///modules/atomia/apache_agent/apache-agent-wildcard.key",
      require => Package["atomia-pa-apache"],
      notify  => Service["atomia-pa-apache"],
    }

    file { "/usr/local/apache-agent/wildcard.crt":
      owner   => root,
      group   => root,
      mode    => 440,
      content => "puppet:///modules/atomia/apache_agent/apache-agent-wildcard.crt",
      notify  => Service["atomia-pa-apache"],
      require => [File["/usr/local/apache-agent/wildcard.key"], Package["atomia-pa-apache"]],
    }
  } else {
    $ssl_generate_var = "nossl"
  }

  atomia::nfsmount { 'mount_content':
    use_nfs3 => $use_nfs3,
    mount_point => '/storage/content',
    nfs_location => $content_share_nfs_location
  }

  atomia::nfsmount { 'mount_config':
    use_nfs3 => $use_nfs3,
    mount_point => '/storage/configuration',
    nfs_location => $config_share_nfs_location
  }

  if $atomia_clustered != 0 {
    exec { "/bin/sed 's/%h/%{X-Forwarded-For}i/' -i ${$pa_conf_available_path}/${$pa_conf_file}":
      unless  => "/bin/grep 'X-Forwarded-For' ${$pa_conf_available_path}/${$pa_conf_file}",
      require => Package["atomia-pa-apache"],
      notify  => Exec["force-reload-apache"],
    }
  }

  if $should_have_pa_apache == 1 {
    file { "/usr/local/apache-agent/settings.cfg":
      owner   => root,
      group   => root,
      mode    => 440,
      content => template("atomia/apache_agent/settings.erb"),
      require => Package["atomia-pa-apache"],
    }
  }

  file { "${$pa_conf_available_path}/${$pa_conf_file}":
      ensure  => present,
      content => template("atomia/apache_agent/atomia-pa-apache.conf.$lsbdistcodename.erb"),
      require => [Package["atomia-pa-apache"]],
  }

  file { "/etc/statisticscopy.conf":
    owner   => root,
    group   => root,
    mode    => 440,
    content => template("atomia/apache_agent/statisticscopy.erb"),
    require => Package["atomiastatisticscopy"],
  }

  file { "/var/www/cgi-wrappers": mode => 755, }

  # ensuring we have maps folder and needed files inside
  file { "${$maps_path}":
    owner  => root,
    group  => www-data,
    mode   => 2750,
    ensure => directory,
    recurse => true,
  }

  file { "${$maps_path}/frmrs.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  file { "${$maps_path}/parks.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  file { "${$maps_path}/phpvr.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  file { "${$maps_path}/redrs.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  file { "${$maps_path}/sspnd.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  file { "${$maps_path}/users.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  file { "${$maps_path}/vhost.map":
    owner   => root,
    group   => www-data,
    mode    => 440,
    ensure  => present,
    require => File["${$maps_path}"],
  }

  if !defined(File["/etc/apache2/sites-enabled/${$pa_site_enabled}"]) {
    file { "/etc/apache2/sites-enabled/${$pa_site_enabled}":
      ensure  => absent,
      require => Package["apache2"],
      notify  => Service["apache2"],
    }
  }

  if !defined(File["/etc/apache2/sites-available/${$pa_site}"]) {
    file { "/etc/apache2/sites-available/${$pa_site}":
      ensure  => absent,
      require => Package["apache2"],
      notify  => Service["apache2"],
    }
  }

  file { "${$pa_conf_available_path}/001-custom-errors":
    owner   => root,
    group   => root,
    mode    => 444,
    source  => "puppet:///modules/atomia/apache_agent/001-custom-errors",
    require => Package["apache2"],
    notify  => Service["apache2"],
  }

  if $lsbdistrelease == "14.04" {
    file { "/etc/apache2/conf-enabled/001-custom-errors.conf":
    ensure  => link,
    target  => "../conf-available/001-custom-errors",
    require => File["${$pa_conf_available_path}/001-custom-errors"],
    notify  => Service["apache2"],
    }
  }

  file { "/etc/apache2/suexec/www-data":
    owner   => root,
    group   => root,
    mode    => 444,
    source  => "puppet:///modules/atomia/apache_agent/suexec-conf",
    require => [Package["apache2"], Package["apache2-suexec-custom-cgroups-atomia"]],
    notify  => Service["apache2"],
  }

  file { "/etc/cgconfig.conf":
    owner   => root,
    group   => root,
    mode    => 444,
    source  => "puppet:///modules/atomia/apache_agent/cgconfig.conf",
    require => [Package["cgroup-bin"]],
  }

  file { "/storage/configuration/php_session_path":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => 1733,
    require => Package["php5-cgi"],
  }

  file { "/storage/configuration/php.ini":
    replace => "no",
    ensure  => present,
    source  => "puppet:///modules/atomia/apache_agent/php.ini",
    owner   => root,
    group   => root,
    mode    => 644,
  }

  file { "/etc/php5/cgi/php.ini":
    ensure  => link,
    target  => "/storage/configuration/php.ini",
    require => [File["/storage/configuration/php.ini"], Package["php5-cgi"]],
  }

  if $should_have_pa_apache == 1 {
    service { atomia-pa-apache:
      name      => apache-agent,
      enable    => true,
      ensure    => running,
      hasstatus => false,
      pattern   => "python /etc/init.d/apache-agent start",
      subscribe => [Package["atomia-pa-apache"], File["/usr/local/apache-agent/settings.cfg"]],
    }
  }
  
  define arrayPHP {
    $php_version = $name
    # Compile PHP and create wrappers 
    exec { "compile_php_${php_version}" :
      command => "/opt/phpfarm/src/compile.sh ${$php_version}",
      creates => "/opt/phpfarm/inst/bin/php-${$php_version}",
      timeout => 1800,
      onlyif  => "/usr/bin/test -f /opt/phpfarm/src/options.sh",
      require => Package["libapache2-mod-fcgid-atomia"],
    }
    exec {"check_php_install_${php_version}":
      command => "/opt/phpfarm/inst/bin/php-${$php_version} --version | grep built",
      onlyif  => "/usr/bin/test -f /opt/phpfarm/inst/bin/php-${$php_version}",
    }
    file { "/var/www/cgi-wrappers/php-fcgid-wrapper-${php_version}":
      owner   => root,
      group   => root,
      mode    => 555,
      content => template("atomia/apache_agent/php-fcgid-wrapper-custom.erb"),
      require => [Exec["compile_php_${php_version}"], Exec["check_php_install_${php_version}"]],
    }
  }
  
  arrayPHP { $php_versions: }
  
  if ($should_have_php_farm == 1) and ($lsbdistrelease == "14.04") {
    # Download prerequisites 
    $phpcompilepackages = [ git, libxml2, libxml2-dev, libssl-dev, libcurl4-openssl-dev, pkg-config, libicu-dev, libmcrypt-dev, php5-dev, libgeoip-dev, libmagickwand-dev, libjpeg-dev, libpng12-dev, libmysqlclient-dev ]
    package { $phpcompilepackages:
      ensure => "installed",
      require => Package["libapache2-mod-fcgid-atomia"],
    }
    exec { "clone_phpfarm_repo" :
      command => "/usr/bin/git clone git://git.code.sf.net/p/phpfarm/code /opt/phpfarm",
      unless  => "/usr/bin/test -f /opt/phpfarm/src/options.sh",
      require => [Package["libapache2-mod-fcgid-atomia"], Package["php5-dev"], Package["git"]],
    }
    file { "/opt/phpfarm/src/options.sh":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet:///modules/atomia/apache_agent/php-options.sh",
      require => Exec["clone_phpfarm_repo"],
    }
    file { "/etc/apache2/conf/phpversions.conf":
      owner   => root,
      group   => root,
      mode    => 644,
      content => template("atomia/apache_agent/phpversions.erb"),
    }
  }

  if !defined(Service['apache2']) {
    service { apache2:
      name   => apache2,
      enable => true,
      ensure => running,
    }
  }

  if !defined(Exec['force-reload-apache']) {
    exec { "force-reload-apache":
      refreshonly => true,
      before      => Service["apache2"],
      command     => "/etc/init.d/apache2 force-reload",
    }
  }

  if !defined(Exec['/usr/sbin/a2enmod rewrite']) {
    exec { "/usr/sbin/a2enmod rewrite":
      unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/rewrite.load",
      require => Package["apache2"],
      notify  => Exec["force-reload-apache"],
    }
  }

  exec { "/usr/sbin/a2enmod userdir":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/userdir.load",
    require => Package["apache2"],
    notify  => Exec["force-reload-apache"],
  }

  exec { "/usr/sbin/a2enmod fcgid":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/fcgid.load",
    require => Package["apache2"],
    notify  => Exec["force-reload-apache"],
  }

  exec { "/usr/sbin/a2enmod suexec":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/suexec.load",
    require => [Package["apache2-suexec-custom-cgroups-atomia"], Package["apache2"]],
    notify  => Exec["force-reload-apache"],
  }

  exec { "/usr/sbin/a2enmod expires":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/expires.load",
    require => Package["apache2"],
    notify  => Exec["force-reload-apache"],
  }

  exec { "/usr/sbin/a2enmod headers":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/headers.load",
    require => Package["apache2"],
    notify  => Exec["force-reload-apache"],
  }

  exec { "/usr/sbin/a2enmod deflate":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/deflate.load",
    require => Package["apache2"],
    notify  => Exec["force-reload-apache"],
  }

  exec { "/usr/sbin/a2enmod include":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/include.load",
    require => Package["apache2"],
    notify  => Exec["force-reload-apache"],
  }
}