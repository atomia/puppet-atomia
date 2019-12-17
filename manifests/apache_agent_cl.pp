## Atomia CloudLinux

### Deploys and configures an apache webserver cluster node with the atomia apache agent and CloudLinux

### Variable documentation
#### username: The username to require when accessing the apache agent.
#### password: The password to require when accessing the apache agent.
#### should_have_pa_apache: Defines if this node should have a copy of the apache agent installed or not.
#### content_share_nfs_location: The location of the NFS share for customer website content. Example: 192.168.33.21:/export/content
#### config_share_nfs_location: The location of the NFS share for web cluster configuration. Example: 192.168.33.21:/export/configuration
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### cluster_ip: The virtual IP of the apache cluster.
#### apache_agent_ip: The IP or hostname of the apache agent used by Automation Server to provision apache websites.
#### maps_path: The path here the apache website and user maps are stored.
#### cloudlinux_agent_secret: Secret key for authenticating to the CloudLinux agent

### Validations
##### username(advanced): %username
##### password(advanced): %password
##### should_have_pa_apache(advanced): %int_boolean
##### content_share_nfs_location(advanced): %nfs_share
##### config_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %int_boolean
##### cluster_ip: %ip
##### apache_agent_ip(advanced): %ip_or_hostname
##### maps_path(advanced): %path
##### cloudlinux_agent_secret: %password

class atomia::apache_agent_cl (
  $username                   = 'automationserver',
  $password,
  $should_have_pa_apache      = '1',
  $content_share_nfs_location = '',
  $config_share_nfs_location  = '',
  $use_nfs3                   = '1',
  $cluster_ip,
  $apache_agent_ip            = '',
  $maps_path                  = '/storage/configuration/maps',
  $is_master                  = 1,
  $cloudlinux_agent_secret,
) {

  $daggre_ip                    = hiera('atomia::daggre::ip_addr','atomia123')
  $cloudlinux_database_password = hiera('atomia::daggre::cloudlinux_database_password','atomia123')
  $lve_postgres_backend_sed_cmd  = '/usr/bin/sed -i "s/db_type = sqlite/db_type = postgresql/" /etc/sysconfig/lvestats2'
  $lve_postgres_backend_grep_cmd = '/usr/bin/grep "^db_type = postgresql" /etc/sysconfig/lvestats2'

  # Now we add the protect base packge in order for CloudLinux to pull the right dependencies
  package { 'yum-plugin-protectbase':
    ensure => installed
  }
  ->
  # Create the needed protect file
  file { '/etc/yum/pluginconf.d/rhnplugin.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('atomia/apache_agent/rhnplugin.conf.erb'),
    require => Package['yum-plugin-protectbase'],
    notify  => Exec['add epel repo']
  }
  ->
  # First we need to add the repo and enable it
  exec { 'add epel repo':
    command => '/usr/bin/rpm -Uhv http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm',
    unless  => "/usr/bin/rpm -qi epel-release | /bin/grep  -c 'Build Date'",
    require => [Package['yum-plugin-protectbase'], File['/etc/yum/pluginconf.d/rhnplugin.conf']],
    notify  => Exec['enable epel repo'],
    refreshonly => true
  }
  ->
  exec { 'enable epel repo':
    command => '/usr/bin/yum-config-manager --enable epel',
    before => Class['atomia::nagios::client'],
    refreshonly => true
  }

  # All the code now goes here as all this above is needed first
    $packages_to_install = [
      'atomiastatisticscopy', 'httpd', 'cronolog', 'atomia-python-ZSI', 'mod_ssl'
    ]

    package { $packages_to_install:
      ensure  => installed,
      require => Exec['enable epel repo'],
      notify  => Exec['apply-firewall-httpd']
    }

    # Install lve-stats
    exec { 'install lve-stats2':
      command => '/usr/bin/yum -y install lve-stats --enablerepo=cloudlinux-updates-testing',
      unless  => '/usr/bin/rpm -qa | /bin/grep -c lve-stats-2',
      require => [Package['cagefs']],
    }

    exec { 'update lve-stats connection string':
      command => "/usr/bin/sed -i 's#connect_string =.*#connect_string = atomia-lve:${cloudlinux_database_password}@${daggre_ip}/lve#' /etc/sysconfig/lvestats2",
      unless  => "/usr/bin/grep -c 'connect_string = atomia-lve:${cloudlinux_database_password}@${daggre_ip}/lve' /etc/sysconfig/lvestats2",
      notify  => Service['lvestats'],
      require => Exec['install lve-stats2'],
    }

    # Set postgres backend
    exec { 'set postgres backend':
      command => $lve_postgres_backend_sed_cmd,
      unless  => $lve_postgres_backend_grep_cmd,
      notify  => Exec['create lve database'],
      require => Exec['install lve-stats2'],
    }

    exec { 'create lve database':
      command     => "/usr/sbin/lve-create-db && touch /storage/configuration/cloudlinux/lve_db_${daggre_ip}",
      creates     => "/storage/configuration/cloudlinux/lve_db_${daggre_ip}",
      require     => [Exec['set postgres backend'],File['/storage/configuration/cloudlinux']],
    }

    service { 'lvestats':
      ensure  => running,
      require => [Exec['install lve-stats2'],Exec['set postgres backend'],Exec['create lve database']],
    }

    # Install alt-php
    package { 'lvemanager':
      ensure => installed,
      require => [Package['cagefs']],
    }

    exec { 'install altphp':
        command => '/usr/bin/yum -y groupinstall alt-php',
        timeout => 1800,
        unless  => '/usr/bin/rpm -qa | /bin/grep -c alt-php70',
        require => [Package['cagefs']],
    }

    file {'/storage/configuration/cloudlinux/lve_packages':
      ensure  => 'present',
      replace => 'no',
      content => '#lve packages',
      mode    => '0644',
      require => [Package['lvemanager'],File['/storage']],
    }

    file {'/storage/configuration/cloudlinux/lve_packages.sh':
      ensure  => 'present',
      source  => 'puppet:///modules/atomia/apache_agent/lve_packages.sh',
      mode    => '0755',
      require => [Package['lvemanager'],File['/storage']],
    }
    
    # There was a possible bug, that some CloudLinux nodes were not having anything in the /etc/sysconfig/cloudlinux file.
    # So we need to check if the /etc/sysconfig/cloudlinux exists if not then we need to populate it with defaults.
    # If the file is already there then we don't create it just add the CUSTOM_GETPACKAGE_SCRIPT.

    file { '/etc/sysconfig/cloudlinux':
      ensure  => 'present',
      replace => 'no', 
      source => "puppet:///modules/atomia/apache_agent/cloudlinux",
      mode    => '0644',
    } ->
    exec {'enable lve package lookup':
      command => '/usr/bin/echo -e "\nCUSTOM_GETPACKAGE_SCRIPT=/storage/configuration/cloudlinux/lve_packages.sh" >> /etc/sysconfig/cloudlinux',
      unless  => '/bin/grep -c "/storage/configuration/cloudlinux/lve_packages.sh" /etc/sysconfig/cloudlinux'
    }
    
    # Selectorctl was unable to add extensions and so it didn't work properly as it couldn't find the phpnative.dat file.
    # Because of this, we need to ensure that there is a phpnative.dat file so it would work.
    # The file can be empty so we can just touch it and leave it empty.

    exec {'create phpnative.dat':
      command => '/bin/touch /var/lve/phpnative.dat',
      require => [Package['lvemanager']],
    }

    # Install Cagefs
    package { 'cagefs':
      ensure  => present,
      require => [Exec['enable epel repo'], Package[$packages_to_install]],
      notify  => Exec['init cagefs'],
    }

    exec { 'init cagefs':
      command     => '/usr/sbin/cagefsctl --init',
      require     => Package['cagefs'],
      refreshonly => true,
      notify      => Exec['enable cagefs'],
    }

    exec { 'enable cagefs':
      command     => '/usr/sbin/cagefsctl --disable-all',
      require     => Package['cagefs'],
      refreshonly => true,
    }

    # Install mod_lsapi
    exec { 'install mod_lsapi':
      command => '/usr/bin/yum -y install liblsapi liblsapi-devel mod_lsapi gcc gcc-c++ cmake httpd-devel --enablerepo=cloudlinux-updates-testing',
      unless  => '/usr/bin/rpm -qa | /bin/grep -c liblsapi',
      require => Package['cagefs'],
      notify  => Exec['setup mod_lsapi']
    }

    exec { 'setup mod_lsapi':
      command     => '/usr/bin/switch_mod_lsapi --setup',
      refreshonly => true
    }

    file { '/etc/httpd/conf.d/lsapi.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('atomia/apache_agent/lsapi.conf.erb'),
      require => Exec['install mod_lsapi'],
      notify  => Service['httpd']
    }

    # Install mod_hostinglimits
    package { 'mod_hostinglimits':
      ensure  => present,
      require => Package['httpd'],
    }

    file { '/etc/httpd/conf.d/modhostinglimits.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('atomia/apache_agent/modhostinglimits.conf.erb'),
      require => Package['mod_hostinglimits'],
      notify  => Service['httpd']
    }

    if $content_share_nfs_location == '' {
      $internal_zone = hiera('atomia::active_directory::domain_name','')

      package { 'glusterfs-client': ensure => present, }

      if !defined(File['/storage']) {
        file { '/storage':
          ensure => directory,
        }
      }

      fstab::mount { '/storage/content':
        ensure  => 'mounted',
        device  => "gluster.${internal_zone}:/web_volume",
        options => 'defaults,_netdev',
        fstype  => 'glusterfs',
        require => [Package['glusterfs-client'],File['/storage']],
      }

      fstab::mount { '/storage/configuration':
        ensure  => 'mounted',
        device  => "gluster.${internal_zone}:/config_volume",
        options => 'defaults,_netdev',
        fstype  => 'glusterfs',
        before  => [File['/storage/configuration/cloudlinux'],Exec['create lve database']],
        require => [ Package['glusterfs-client'],File['/storage']],
      }
    }
    else
    {
      atomia::nfsmount { 'mount_content':
        use_nfs3     => '1',
        mount_point  => '/storage/content',
        nfs_location => $content_share_nfs_location,
      }

      atomia::nfsmount { 'mount_configuration':
        use_nfs3     => '1',
        mount_point  => '/storage/configuration',
        before       => [File['/storage/configuration/cloudlinux'],Exec['create lve database']],
        nfs_location => $config_share_nfs_location,
      }
    }

    if $should_have_pa_apache == '1' {
      package { 'atomia-pa-apache':
        ensure  => present,
        require => [Package['httpd'], Package['cronolog'], Package['atomia-python-ZSI'], Package['mod_ssl'] ],
        notify  => Exec['apply-firewall-apache-agent']
      }

      file { '/storage/configuration/cloudlinux/phpversions.conf':
        ensure  => present,
      }

      package { 'nodejs':
        ensure  => present,
        require => Package['cagefs'],
      }

      package { 'atomia-cloudlinux-agent':
        ensure  => present,
        require => Package['nodejs'],
        notify  => Exec['apply-firewall-cl-agent']
      }

      service { 'atomia-cloudlinux-agent':
        ensure  => running,
        require => Package['atomia-cloudlinux-agent'],
      }

      if $is_master == 1 {
        exec { 'sync php versions':
          command => "/usr/bin/curl -X PUT -H \"Authorization: ${cloudlinux_agent_secret}\" http://localhost:8000/php/sync -v",
          require => [Package['atomia-cloudlinux-agent'], Exec['install altphp'], File['/etc/httpd/conf/phpversions.conf']],
        }
      }

      file { '/etc/httpd/conf/phpversions.conf':
        ensure  => 'link',
        target  => '/storage/configuration/cloudlinux/phpversions.conf',
        require => [File['/storage/configuration/cloudlinux'], File['/storage/configuration/cloudlinux/phpversions.conf']],
        force   => true,
      }

      file {'/etc/cl.selector/symlinks.rules':
        ensure  => 'present',
        content => 'php.d.location = selector',
        mode    => '0644',
        require => [File['/etc/httpd/conf/phpversions.conf']],
        notify  => Exec['apply-symlinks-rules'],
      }

      exec { 'apply-symlinks-rules':
        command     => '/usr/bin/selectorctl --apply-symlinks-rules',
        refreshonly => true
      }
    }
    
    # Blacklist file allows us to limit the binaries, files, folders that are in CageFS environment.
    # Sometimes you need to block certian tools like gcc, g++ not be able to be used by users.
    # As the system can use PHP exec() we need to ensure to block anything that can be misued.
    # When the black.list file changes on master the rules will be aplied on the client nodes.
    # CageFS needs to be updated so we do a force update to apply the new list.

    file {'/etc/cagefs/black.list':
      ensure  => 'present',
      source  => 'puppet:///modules/atomia/apache_agent/black.list',
      mode    => '0600',
      require     => Package['cagefs'],
      notify  => Exec['apply-blacklist']
    }

    exec { 'apply-blacklist':
      command     => '/usr/sbin/cagefsctl --force-update',
      refreshonly => true
    }

    # We need to ensure the service is running and that it's enabled on startup.

    service { 'httpd':
      ensure  => running,
      enable  => true
    }

    # These firewall rules are needed on RHEL based systems like CentOS 7 and CloudLinux 7.
    # IPtables has been replaced with firewall-cmd, so we add the ports via that tool.
    # All these firewall rules need to be aplied after the packages are installed.
    # By default only port 22 is allowed and nothing else to listen.

    exec { 'apply-firewall-httpd':
      command => '/usr/bin/firewall-cmd --zone=public --add-port=80/tcp --permanent && /usr/bin/firewall-cmd --reload',
      require => Package['httpd'],
      unless  => '/usr/sbin/iptables -S | /usr/bin/grep "80 "'
    }

    exec { 'apply-firewall-cl-agent':
      command => '/usr/bin/firewall-cmd --zone=public --add-port=8000/tcp --permanent && /usr/bin/firewall-cmd --reload',
      require => Package['atomia-cloudlinux-agent'],
      unless  => '/usr/sbin/iptables -S | /usr/bin/grep 8000'
    }

    exec { 'apply-firewall-apache-agent':
      command => '/usr/bin/firewall-cmd --zone=public --add-port=9999/tcp --permanent && /usr/bin/firewall-cmd --reload',
      require => Package['atomia-pa-apache'],
      unless  => '/usr/sbin/iptables -S | /usr/bin/grep 9999'
    }

    exec { 'apply-firewall-nagios':
      command => '/usr/bin/firewall-cmd --zone=public --add-port=5666/tcp --permanent && /usr/bin/firewall-cmd --reload',
      require => Class['atomia::nagios::client'],
      unless  => '/usr/sbin/iptables -S | /usr/bin/grep 5666'
    }

    # We need to adapt systemd services to wait for mounts before we start cagefs and lvestats.
    # Finally we update the service to apply the changes to the .service files.
    # All of the commands are run sequentially to ensure the right flow.
    # ini_settings is added to Puppetfile in order to use this module.

    ini_setting { 'condition LVEctl service file':
      ensure  => present,
      path    => '/usr/lib/systemd/system/lvectl.service',
      section => 'Unit',
      setting => 'ConditionPathIsMountPoint',
      value   => '/storage/configuration/',
      require => [Exec['install lve-stats2'],Exec['set postgres backend'],Exec['create lve database']]
    } ->
    ini_setting { 'condition LVEstats service file':
      ensure  => present,
      path    => '/usr/lib/systemd/system/lvestats.service',
      section => 'Unit',
      setting => 'ConditionPathIsMountPoint',
      value   => '/storage/configuration/',
      require => [Exec['install lve-stats2'],Exec['set postgres backend'],Exec['create lve database']]
    } ->
    ini_setting { 'condition CageFS service file':
      ensure  => present,
      path    => '/usr/lib/systemd/system/cagefs.service',
      section => 'Unit',
      setting => 'ConditionPathIsMountPoint',
      value   => '/storage/configuration/',
      require => [Exec['install lve-stats2'],Exec['set postgres backend'],Exec['create lve database'],Package['cagefs']]
    } ->
    exec { 'apply systemd changes':
      command => '/bin/systemctl daemon-reload',
      require => [Package['cagefs'],Exec['install lve-stats2'],Exec['set postgres backend'],Exec['create lve database']]
    }

    file { '/etc/httpd/conf.d/atomia-pa-apache.conf':
      ensure  => present,
      content => template('atomia/apache_agent/atomia-pa-apache-cl.conf.erb'),
      require => Package['atomia-pa-apache'],
      notify  => Service['httpd'],
    }

    # CloudLinux shared configuration
    file { '/storage/configuration/cloudlinux':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0701',
      require => [Package['cagefs']],
    }

    file { '/storage/configuration/cloudlinux/users.enabled':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0701',
      require => File['/storage/configuration/cloudlinux']
    }

    file { '/etc/cagefs/users.enabled':
      ensure  => 'link',
      target  => '/storage/configuration/cloudlinux/users.enabled',
      require => File['/storage/configuration/cloudlinux'],
      force   => true,
    }

    file { '/storage/configuration/cloudlinux/cagefs_var':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0751',
      require => File['/storage/configuration/cloudlinux']
    }

    file { '/var/cagefs':
      ensure  => 'link',
      target  => '/storage/configuration/cloudlinux/cagefs_var',
      require => [File['/storage/configuration/cloudlinux/cagefs_var'], Exec['init cagefs']],
      force   => true,
    }

    file { '/storage/configuration/cloudlinux/cagefs_container':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/storage/configuration/cloudlinux']
    }

    file { '/etc/container':
      ensure  => 'link',
      target  => '/storage/configuration/cloudlinux/cagefs_container',
      require => [File['/storage/configuration/cloudlinux/cagefs_container'], Exec['init cagefs']],
      force   => true,
    }

    file { $maps_path:
      ensure  => directory,
      owner   => 'root',
      group   => 'apache',
      mode    => '2750',
      recurse => true,
      require => [File['/storage/configuration/cloudlinux']],
    }

    file { '/storage/configuration/cloudlinux/cagefs_container/ve.cfg':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      replace => 'no',
      content => template('atomia/apache_agent/ve.cfg.erb'),
      require => File['/etc/container']
    }

    $maps_to_ensure = [
      "${maps_path}/frmrs.map", "${maps_path}/parks.map", "${maps_path}/phpvr.map", "${maps_path}/redrs.map", "${maps_path}/sspnd.map",
      "${maps_path}/users.map", "${maps_path}/vhost.map", "${maps_path}/proxy.map"
    ]

    file { $maps_to_ensure:
      ensure  => present,
      owner   => 'root',
      group   => 'apache',
      mode    => '0440',
      require => File[$maps_path],
    }
}
