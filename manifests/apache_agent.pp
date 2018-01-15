## Atomia apache agent

### Deploys and configures an apache webserver cluster node with the atomia apache agent.

### Variable documentation
#### username: The username for accessing the apache agent.
#### password: The password for accessing the apache agent.
#### atomia_clustered: Defines if this is a clustered instance or not.
#### should_have_pa_apache: Defines if this node should have a copy of the apache agent installed or not.
#### content_share_nfs_location: The location of the NFS share for customer website content. Example: 192.168.33.21:/export/content
#### config_share_nfs_location: The location of the NFS share for web cluster configuration. Example: 192.168.33.21:/export/config
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### cluster_ip: The virtual IP of the apache cluster.
#### apache_agent_ip: The IP or hostname of the apache agent used by Automation Server to provision apache websites. Usually the first node in the cluster.
#### maps_path: The path here the apache website and user maps are stored.
#### should_have_php_farm: Toggles if we are to build and install a set of custom PHP versions or use the distribution default.
#### php_versions: If using custom PHP versions, then this is a comma separated list of the versions to compile and install.
#### php_extension_packages: Determines which PHP extensions to install (comma separated list of package names).
#### apache_modules_to_enable: Determines which Apache modules to enable (comma separated list of modules).
#### sendmail_path: path to the sendmail or ssmtp what to set in php.ini to use for mail function, or leave empty for disabled mail sending via php mail.
#### relay_mail_server_ip: IP or Hostname of the mail server which will relay mail sent by sendmail
#### custom_domain_from_mail: Enable or disable changing of domain when sending mail by sendmail 1 or 0

### Validations
##### username(advanced): %username
##### password(advanced): %password
##### atomia_clustered(advanced): %int_boolean
##### should_have_pa_apache(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %int_boolean
##### cluster_ip: %ip
##### apache_agent_ip: %ip_or_hostname
##### maps_path(advanced): %path
##### should_have_php_farm(advanced): %int_boolean
##### php_versions(advanced): ^[0-9]+\.[0-9]+\.[0-9]+(,[0-9]+\.[0-9]+\.[0-9]+)*$
##### php_extension_packages(advanced): ^.*$
##### apache_modules_to_enable(advanced): ^[a-z0-9_-]+(,[a-z0-9_-]+)$
##### sendmail_path: .
##### relay_mail_server_ip(advanced): %ip_or_hostname
##### custom_domain_from_mail(advanced): %int_boolean

class atomia::apache_agent (
  $username                   = 'automationserver',
  $password,
  $atomia_clustered           = '1',
  $should_have_pa_apache      = '1',
  $content_share_nfs_location = '',
  $config_share_nfs_location  = '',
  $use_nfs3                   = '1',
  $cluster_ip,
  $apache_agent_ip            = '',
  $maps_path                  = '/storage/configuration/maps',
  $should_have_php_farm       = '0',
  $php_versions               = '5.4.45,5.5.29',
  $php_extension_packages     = 'php-gd,php-imagick,php-sybase,php-mysql,php-odbc,php-curl,php-pgsql',
  $apache_modules_to_enable   = 'rewrite,userdir,fcgid,suexec,expires,headers,deflate,include,authz_groupfile',
  $relay_mail_server_ip       = '',
  $custom_domain_from_mail    = '1',
  $sendmail_path              = '/usr/sbin/sendmail -t -i'
) {

  if $::lsbdistrelease == '14.04' or $::lsbdistrelease == '16.04' {
    $pa_conf_available_path = '/etc/apache2/conf-available'
    $pa_conf_file           = 'atomia-pa-apache.conf'
    $pa_site                = '000-default.conf'
    $pa_site_enabled        = '000-default.conf'
  } else {
    $pa_conf_available_path = '/etc/apache2/conf.d'
    $pa_conf_file           = 'atomia-pa-apache.conf'
    $pa_site                = 'default'
    $pa_site_enabled        = '000-default'
  }

  if $should_have_pa_apache == '1' {
    package { 'atomia-pa-apache':
      ensure  => present,
      require => Package['apache2'],
    }
  }

  if($::operatingsystem == 'CloudLinux') {
    exec { 'add epel repo':
      command => '/usr/bin/rpm -Uhv http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm',
    }

    $packages_to_install = [
      'atomiastatisticscopy', 'httpd'
    ]
  } else {
    if  $::lsbdistrelease == '16.04' {
      $packages_to_install = [
        'apache2-suexec-custom-cgroups-atomia',
        'atomiastatisticscopy',
        'cgroup-bin',
        'libapache2-mod-fcgid-atomia',
        'libexpat1',
        'php-cgi',
      ]

      file { '/storage/configuration/php_session_path':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '1733',
        require => Package['php-cgi'],
      }
      file { '/etc/php/7.0/cgi/php.ini':
        ensure  => link,
        target  => '/storage/configuration/php.ini',
        require => [File['/storage/configuration/php.ini'], Package['php-cgi']],
      }

    }
    else {
      $packages_to_install = [
        'apache2-suexec-custom-cgroups-atomia',
        'atomiastatisticscopy',
        'cgroup-bin',
        'libapache2-mod-fcgid-atomia',
        'libexpat1',
        'php5-cgi',
      ]

      file { '/storage/configuration/php_session_path':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '1733',
        require => Package['php5-cgi'],
      }
      file { '/etc/php5/cgi/php.ini':
        ensure  => link,
        target  => '/storage/configuration/php.ini',
        require => [File['/storage/configuration/php.ini'], Package['php5-cgi']],
      }

    }

    if !defined(Package['apache2']) {
      package { 'apache2': ensure => present }
    }
  }

  package { $packages_to_install: ensure => installed }

  $php_package_array = split($php_extension_packages, ',')
  package { $php_package_array: ensure => installed }

  if $content_share_nfs_location == '' {
    $gluster_hostname = hiera('atomia::glusterfs::gluster_hostname','')

    package { 'glusterfs-client': ensure => present, }

    if !defined(File['/storage']) {
      file { '/storage':
        ensure => directory,
      }
    }

    fstab::mount { '/storage/content':
      ensure  => 'mounted',
      device  => "${gluster_hostname}:/web_volume",
      options => 'defaults,_netdev',
      fstype  => 'glusterfs',
      require => [Package['glusterfs-client'],File['/storage']],
    }
    fstab::mount { '/storage/configuration':
      ensure  => 'mounted',
      device  => "${gluster_hostname}:/config_volume",
      options => 'defaults,_netdev',
      fstype  => 'glusterfs',
      require => [ Package['glusterfs-client'],File['/storage']],
    }
  }
  else
  {
    atomia::nfsmount { 'mount_content':
      use_nfs3     => '1',
      mount_point  => '/storage/content',
      nfs_location => $content_share_nfs_location
    }

    atomia::nfsmount { 'mount_configuration':
      use_nfs3     => '1',
      mount_point  => '/storage/configuration',
      nfs_location => $config_share_nfs_location
    }
  }

  if $should_have_pa_apache == '1' {
    file { '/usr/local/apache-agent/settings.cfg':
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      content => template('atomia/apache_agent/settings.erb'),
      require => Package['atomia-pa-apache'],
    }

    file { "${pa_conf_available_path}/${pa_conf_file}":
      ensure  => present,
      content => template('atomia/apache_agent/atomia-pa-apache.conf.erb'),
      require => [Package['atomia-pa-apache']],
    }

    exec { "/usr/sbin/a2enconf ${pa_conf_file}":
      unless  => "/usr/bin/test -f /etc/apache2/conf-enabled/${pa_conf_file}",
      require => Package['apache2'],
      notify  => Service['apache2'],
    }

  }

  file { '/etc/statisticscopy.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template('atomia/apache_agent/statisticscopy.erb'),
    require => Package['atomiastatisticscopy'],
  }

  file { '/var/log/httpd':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
    before => Service['apache2'],
  }

  file { '/var/www/':
    ensure  => directory,
  }

  file { '/var/www/cgi-wrappers':
    ensure  => directory,
    mode    => '0755',
    recurse => true,
  }

  file { $maps_path:
    ensure  => directory,
    owner   => 'root',
    group   => 'www-data',
    mode    => '2750',
    recurse => true,
  }

  file { '/storage/configuration/apache':
    ensure  => directory,
    owner   => 'root',
    group   => 'www-data',
    mode    => '2750',
    recurse => true,
  }

  $maps_to_ensure = [
    "${maps_path}/frmrs.map", "${maps_path}/parks.map", "${maps_path}/phpvr.map", "${maps_path}/redrs.map", "${maps_path}/sspnd.map",
    "${maps_path}/users.map", "${maps_path}/vhost.map"
  ]

  file { $maps_to_ensure:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0440',
    require => File[$maps_path],
  }


  if !defined(File["/etc/apache2/sites-enabled/${pa_site_enabled}"]) {
    file { "/etc/apache2/sites-enabled/${pa_site_enabled}":
      ensure  => absent,
      require => Package['apache2'],
      notify  => Service['apache2'],
    }
  }

  if !defined(File["/etc/apache2/sites-available/${pa_site}"]) {
    file { "/etc/apache2/sites-available/${pa_site}":
      ensure  => absent,
      require => Package['apache2'],
      notify  => Service['apache2'],
    }
  }

  file { "${pa_conf_available_path}/001-custom-errors":
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/atomia/apache_agent/001-custom-errors',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  if $::lsbdistrelease == '14.04' or $::lsbdistrelease == '16.04' {
    file { '/etc/apache2/conf-enabled/001-custom-errors.conf':
      ensure  => link,
      target  => '../conf-available/001-custom-errors',
      require => File["${pa_conf_available_path}/001-custom-errors"],
      notify  => Service['apache2'],
    }
  }

  file { '/etc/apache2/suexec/www-data':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/atomia/apache_agent/suexec-conf',
    require => [Package['apache2'], Package['apache2-suexec-custom-cgroups-atomia']],
    notify  => Service['apache2'],
  }

  file { '/etc/cgconfig.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/atomia/apache_agent/cgconfig.conf',
    require => [Package['cgroup-bin']],
  }

  #enable sendmail ssmtp install
  if $::sendmail_path != '' {

    #if relay_mail_server_ip is set then use the value that has been set via puppetGUI or use the master_ip of mailserver 
    if $relay_mail_server_ip != '' {
      $relay_server_ip = $relay_mail_server_ip
    } else {
      $relay_server_ip = hiera('atomia::mailserver::master_ip','')
    }
    
    $sendmail_path_erb = hiera('atomia::apache_agent::sendmail_path','/usr/sbin/sendmail -t -i') #use default from hiera
    $custom_domain_from_mail_string = 'YES'
    
    if $custom_domain_from_mail != '1' {
      $custom_domain_from_mail_string = 'NO'
    }

    package { 'ssmtp': ensure => present, }

    file { '/etc/ssmtp/ssmtp.conf':
      ensure  => present,
      content  => template('atomia/apache_agent/ssmtp.conf.erb'), #'puppet:///modules/atomia/apache_agent/php.ini',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => [ Package['ssmtp'] ],
    }
    
    file { '/storage/configuration/php.ini':
      ensure  => present,
      content  => template('atomia/apache_agent/php.ini.erb'), #'puppet:///modules/atomia/apache_agent/php.ini',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  } else {
    file { '/storage/configuration/php.ini':
      ensure  => present,
      replace => 'no',
      content => 'puppet:///modules/atomia/apache_agent/php.ini',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }
  
  if $should_have_pa_apache == '1' {
    service { 'atomia-pa-apache':
      ensure    => running,
      name      => apache-agent,
      enable    => true,
      hasstatus => false,
      pattern   => 'python /etc/init.d/apache-agent start',
      subscribe => [Package['atomia-pa-apache'], File['/usr/local/apache-agent/settings.cfg']],
    }
  }


  $php_versions_array = split($php_versions, ',')
  arrayPHP { $php_versions_array: }

  if ($should_have_php_farm == '1') and ($::lsbdistrelease == '14.04') or $::lsbdistrelease == '16.04' {

    $phpcompilepackages = [
      'git',
      'libcurl4-openssl-dev',
      'libgeoip-dev',
      'libicu-dev',
      'libjpeg-dev',
      'libmagickwand-dev',
      'libmcrypt-dev',
      'libmysqlclient-dev',
      'libpng12-dev',
      'libssl-dev',
      'libxml2',
      'libxml2-dev',
      'pkg-config',
    ]

    if $::lsbdistrelease == '16.04' {
      package {'php-dev': ensure => present }
      exec { 'clone_phpfarm_repo' :
        command => '/usr/bin/git clone git://git.code.sf.net/p/phpfarm/code /opt/phpfarm',
        unless  => '/usr/bin/test -f /opt/phpfarm/src/options.sh',
        require => [Package['libapache2-mod-fcgid-atomia'], Package['php-dev'], Package['git']],
      }
    } else {
      package {'php5-dev': ensure => present }
      exec { 'clone_phpfarm_repo' :
        command => '/usr/bin/git clone git://git.code.sf.net/p/phpfarm/code /opt/phpfarm',
        unless  => '/usr/bin/test -f /opt/phpfarm/src/options.sh',
        require => [Package['libapache2-mod-fcgid-atomia'], Package['php5-dev'], Package['git']],
      }
    }

    package { $phpcompilepackages:
      ensure  => 'installed',
      require => Package['libapache2-mod-fcgid-atomia'],
    }

    file { '/opt/phpfarm/src/options.sh':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/atomia/apache_agent/php-options.sh',
      require => Exec['clone_phpfarm_repo'],
    }

    $php_branches_array = extract_major_minor($php_versions_array)

    file { '/etc/apache2/conf/phpversions.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('atomia/apache_agent/phpversions.erb'),
      require => [Package['atomia-pa-apache']],
      notify  => Service['apache2'],
    }
  }

  if !defined(Service['apache2']) {
    service { 'apache2':
      ensure => running,
      enable => true,
    }
  }

  if !defined(Exec['force-reload-apache']) {
    exec { 'force-reload-apache':
      refreshonly => true,
      before      => Service['apache2'],
      command     => '/etc/init.d/apache2 force-reload',
    }
  }

  $apache_modules_to_enable_array = split($apache_modules_to_enable, ',')
  apacheModuleToEnable { $apache_modules_to_enable_array: }
}

define arrayPHP {
  $php_version = $name
  # Compile PHP and create wrappers
  exec { "compile_php_${php_version}" :
    command => "/opt/phpfarm/src/compile.sh ${php_version}",
    creates => "/opt/phpfarm/inst/bin/php-${php_version}",
    timeout => 1800,
    onlyif  => '/usr/bin/test -f /opt/phpfarm/src/options.sh',
    require => Package['libapache2-mod-fcgid-atomia'],
  }
  exec {"check_php_install_${php_version}":
    command => "/bin/sh -c '(/opt/phpfarm/inst/bin/php-${php_version} --version | grep built) && touch /opt/phpfarm/inst/php-${php_version}.tested'",
    creates => "/opt/phpfarm/inst/php-${php_version}.tested",
    onlyif  => "/usr/bin/test -f /opt/phpfarm/inst/bin/php-${php_version}",
    require => Exec["compile_php_${php_version}"]
  }
  file { "/var/www/cgi-wrappers/php-fcgid-wrapper-${php_version}":
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('atomia/apache_agent/php-fcgid-wrapper-custom.erb'),
    require => [Exec["compile_php_${php_version}"], Exec["check_php_install_${php_version}"],File['/var/www/cgi-wrappers']],
  }
}

define apacheModuleToEnable {
  exec { "/usr/sbin/a2enmod ${name}":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/${name}.load",
    require => Package['apache2'],
    notify  => Exec['force-reload-apache'],
  }
}
