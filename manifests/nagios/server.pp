## Nagios Server

### Deploys and configures a Nagios server for monitoring of an Atomia environment

### Variable documentation
#### username: The URL of the Atomia Domain Registration service.
#### password: The username to require for accessing the service.
#### admin_pass: The password to require for accessing the service.

### Validations
##### username(advanced):^[a-z]+$
##### password(advanced): %password


class atomia::nagios::server(
  $username   = "nagiosadmin",
  $password   = ""
) {

  # Set ip correctly when on ec2
  if $ec2_public_ipv4 {
    $nagios_ip = $ec2_public_ipv4
  } else {
    $nagios_ip = $ipaddress_eth0
  }

  $admin_pass = hiera('atomia::config::atomia_admin_password')

  #$apache_ip  = generate('/etc/puppet/modules/atomia/files/lookup_variable.sh', 'apache_agent', 'cluster_ip')

  package { [
      'build-essential',
      'libgd2-xpm-dev',
      'openssl',
      'libssl-dev',
      'apache2-utils',
      'apache2',
      'php5',
      'libapache2-mod-php5',
      'php5-mcrypt',
      'nagios-plugins',
      'nagios-nrpe-server',
      'atomia-manager',
      'ruby1.9.1-dev',
      'python-pkg-resources',
      'nagios-nrpe-plugin'
    ]:
      ensure => installed,
    }

    if ! defined(Package['libwww-mechanize-perl']) {
  		package { 'libwww-mechanize-perl':
  			ensure => installed,
  		}
  	}

    package { ['jgrep']:
  		ensure => installed,
  		provider => 'gem',
  		require	=> [Package['ruby1.9.1-dev']],
	 }

  group { 'nagios-group':
    ensure  => 'present',
    name    => 'nagcmd'
  }

  user { 'nagios-user':
    name    => 'nagios',
    groups  => ['nagcmd'],
    require => Group['nagios-group']
  }

  # Install Nagios 4 has to be done manually
  file { 'install_nagios_script':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/nagios/install_nagios',
    path    => '/root/install_nagios',
    mode    => "0744",
    notify  => Exec['install_nagios'],
    require => [Package['build-essential'], Package['libgd2-xpm-dev'], Package['openssl'], Package['libssl-dev'], Package['apache2'], User['nagios-user']]
  }

  exec { 'install_nagios':
    command     => '/bin/sh /root/install_nagios',
    refreshonly => true,
    notify      => [Exec['enable-nagios-site'], File['nagios-servers-dir']]
  }

  exec { 'enable_rewrite':
    command => '/usr/sbin/a2enmod rewrite',
    unless  => '/usr/bin/test -f /etc/apache2/mods-enabled/rewrite.load',
    notify  => Exec['reload-apache'],
    require => Package['apache2']
  }

  exec { 'enable_cgi':
    command => '/usr/sbin/a2enmod cgi',
    unless  => '/usr/bin/test -f /etc/apache2/mods-enabled/cgi.load',
    notify  => Exec['reload-apache'],
    require => Package['apache2']
  }

  exec { 'reload-apache':
    command     => '/usr/bin/service apache2 restart',
    refreshonly => true
  }

  exec { 'enable-nagios-site':
    command     => '/usr/sbin/a2ensite nagios.conf',
    refreshonly => true,
    notify      => [Exec['reload-apache'], Exec['add-httpasswd-user']],
    require => Package['apache2']
  }

  service { 'nagios':
    ensure => 'running',
    require => [Exec['install_nagios'], Package['apache2']],
  }

  service { 'apache2':
    ensure  => 'running',
    require => Package['apache2']
  }

  exec { 'add-httpasswd-user':
    command     => "/usr/bin/htpasswd -c -b -c /etc/nagios3/htpasswd.users ${username} ${password}",

  }

  # Done installing Nagios

  file { '/usr/local/nagios/etc/objects/atomia-commands.cfg':
    ensure  => 'file',
    owner   => 'nagios',
    content => template('atomia/nagios/commands.cfg.erb'),
    require => Exec['install_nagios']
  }

  file { '/usr/local/nagios/etc/objects/atomia-hostgroups.cfg':
    ensure  => 'file',
    owner   => 'nagios',
    content => template('atomia/nagios/hostgroups.cfg.erb'),
    require => Exec['install_nagios']
  }

  file { '/usr/local/nagios/etc/objects/atomia-services.cfg':
    ensure  => 'file',
    owner   => 'nagios',
    content => template('atomia/nagios/services.cfg.erb'),
    require => Exec['install_nagios']
  }

  file { '/etc/nagios/nrpe.cfg':
    ensure  => 'file',
    owner   => 'nagios',
    content => template('atomia/nagios/nrpe.cfg.erb'),
    require => [Package['nagios-nrpe-server'],Exec['install_nagios']]
  }

  file_line { 'add-plugin-lib':
    path  => '/usr/local/nagios/etc/resource.cfg',
    line  => '$USER2$=/usr/lib/nagios/plugins',
    require => Exec['install_nagios']
  }

  # Mod nagios.cfg, exec cause no Augeas support for Nagios 4 :(
  exec { 'uncomment-servers-dir':
    command => '/bin/sed -i \'s/\#cfg_dir\=\/usr\/local\/nagios\/etc\/servers/cfg_dir\=\/usr\/local\/nagios\/etc\/servers/g\' /usr/local/nagios/etc/nagios.cfg',
    onlyif  => '/bin/grep -c "#cfg_dir=/usr/local/nagios/etc/servers" /usr/local/nagios/etc/nagios.cfg',
    notify  => Service['nagios']
  }

  exec { 'uncomment-commands':
    command => '/bin/sed -i \'s/\#cfg_file\=\/usr\/local\/nagios\/etc\/objects\/commands.cfg/cfg_file\=\/usr\/local\/nagios\/etc\/objects\/commands.cfg/g\' /usr/local/nagios/etc/nagios.cfg',
    onlyif  => '/bin/grep -c "#cfg_file=/usr/local/nagios/etc/objects/commands.cfg" /usr/local/nagios/etc/nagios.cfg',
    notify  => Service['nagios'],
    require => Exec['install_nagios']
  }

  exec { 'comment-default-localhost':
    command => '/bin/sed -i \'s/cfg_file=\/usr\/local\/nagios\/etc\/objects\/localhost.cfg/#cfg_file=\/usr\/local\/nagios\/etc\/objects\/localhost.cfg/\' /usr/local/nagios/etc/nagios.cfg',
    unless  => '/bin/grep -c "#cfg_file=/usr/local/nagios/etc/objects/localhost.cfg" /usr/local/nagios/etc/nagios.cfg',
    notify  => Service['nagios'],
    require => Exec['install_nagios']
  }

  exec { 'add-atomia-commands-cfg':
    command => '/bin/echo "cfg_file=/usr/local/nagios/etc/objects/atomia-commands.cfg" >> /usr/local/nagios/etc/nagios.cfg',
    unless  => '/bin/grep -c "cfg_file=/usr/local/nagios/etc/objects/atomia-commands.cfg" /usr/local/nagios/etc/nagios.cfg',
    require => File['/usr/local/nagios/etc/objects/atomia-commands.cfg'],
    notify  => Service['nagios'],
  }

  exec { 'add-atomia-hostgroups-cfg':
    command => '/bin/echo "cfg_file=/usr/local/nagios/etc/objects/atomia-hostgroups.cfg" >> /usr/local/nagios/etc/nagios.cfg',
    unless  => '/bin/grep -c "cfg_file=/usr/local/nagios/etc/objects/atomia-hostgroups.cfg" /usr/local/nagios/etc/nagios.cfg',
    require => File['/usr/local/nagios/etc/objects/atomia-hostgroups.cfg'],
    notify  => Service['nagios'],
  }

  exec { 'add-atomia-services-cfg':
    command => '/bin/echo "cfg_file=/usr/local/nagios/etc/objects/atomia-services.cfg" >> /usr/local/nagios/etc/nagios.cfg',
    unless  => '/bin/grep -c "cfg_file=/usr/local/nagios/etc/objects/atomia-services.cfg" /usr/local/nagios/etc/nagios.cfg',
    require => File['/usr/local/nagios/etc/objects/atomia-services.cfg'],
    notify  => Service['nagios'],
  }

  # End modding nagios.cfg

  if !defined(File['/usr/local/nagios/libexec/atomia']){
    file { '/usr/local/nagios/libexec/atomia':
      source  => 'puppet:///modules/atomia/nagios/plugins',
      recurse => true,
      require => [Package['nagios-plugins'],Exec['install_nagios']]
    }
  }


  @@nagios_host { 'localhost-host' :
    use                 => 'generic-host',
    host_name           => 'localhost',
    alias               => 'localhost general checks',
    address             => 'localhost' ,
    target              => '/usr/local/nagios/etc/servers/localhost_host.cfg',
    max_check_attempts  => '5'
  }

  @@nagios_service { 'localhost-http':
    host_name           => 'localhost',
    service_description => 'HTTP Linux',
    check_command       => 'check_http_testsite',
    use                 => 'generic-service',
    target              => '/usr/local/nagios/etc/servers/localhost_service.cfg'
  }

  @@nagios_service { "localhost-hcp":
      host_name               => "localhost",
      service_description     => "HCP login",
      check_command           => "check_hcp!Administrator!${admin_pass}",
      use                     => "generic-service",
      target              => '/usr/local/nagios/etc/servers/localhost_service.cfg'
  }

  file { 'nagios-servers-dir':
    ensure  => 'directory',
    path    => '/usr/local/nagios/etc/servers',
    owner   => 'nagios',
    recurse => true,
    notify  => Service['nagios']
  }
  ->
  Nagios_host <<| |>>
  ->
  Nagios_service <<| |>>
  ->
  exec { 'restart-nagios':
    command => '/etc/init.d/nagios reload',
  }


#  host { 'atomia-nagios-test.net':
#		ip	=> $apache_ip,
#	}

  file { '/etc/atomia.conf':
      owner   => 'root',
      group   => 'root',
      mode    => "0644",
      content => template('atomia/nagios/atomia.conf.erb'),
      require => Package["atomia-manager"]
  }

#  file { '/root/setup_atomia_account.sh':
#    owner   => 'root',
#    group   => 'root',
#    mode    => "0777",
#    source  => "puppet:///modules/atomia/nagios/setup_atomia_account.sh",
#    require => [Package['jgrep'],Package['atomia-manager'], Package['python-pkg-resources']],
#    notify  => Exec['/root/setup_atomia_account.sh']
#	}

#	exec { '/root/setup_atomia_account.sh':
#		require	    => [File['/root/setup_atomia_account.sh'], File['/etc/atomia.conf']],
#    refreshonly => true
#	}

@@bind::a { 'Nagios DNS record':
  ensure    => 'present',
  zone      => hiera('atomia::internaldns::zone_name'),
  ptr       => false,
  hash_data => {
    'nagios' => { owner => "${nagios_ip}" },
  },
}

}
