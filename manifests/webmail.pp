## Atomia Webmail server

### Deploys and configures a Roundcube webmail server.

### Variable documentation
#### db_password: The password for the Roundcube database.
#### mysql_root_password: The password for the MySQL root user.

### Validations
##### db_password: %password
##### mysql_root_password(advanced): %password

class atomia::webmail (
  $db_password                    = '',
  $mysql_root_password            = '',
) {

  $mailhost = hiera('atomia::mailserver::master_ip','')
  $publicdomain = hiera('atomia::config::atomia_domain','')

  class { 'apt': }

  package { ['apache2']: ensure => present, }
  ->
  class { '::mysql::server':
    restart                 => true,
    root_password           => $mysql_root_password,
    remove_default_accounts => true,
  }
  ->
  # set debconf properties
  exec { 'set-roundcube-password':
    unless  => 'dpkg-query -l roundcube-core 2>/dev/null',
    command => 'echo roundcube-core roundcube/mysql/app-pass password $db_password | sudo /usr/bin/debconf-set-selections',
    path    => ['/usr/bin/','/bin/'],
  }
  ->
  exec { 'confirm-roundcube-password':
    unless  => 'dpkg-query -l roundcube-core 2>/dev/null',
    command => 'echo roundcube-core roundcube/app-password-confirm password $db_password | sudo /usr/bin/debconf-set-selections',
    path    => ['/usr/bin/','/bin/'],
  }
  ->
  package { ['roundcube', 'roundcube-plugins', 'roundcube-plugins-extra', 'tinymce']:
    ensure  => present,
    require => [Package['apache2'], Package['mysql-server'], ],
  }
  ->
  file { '/etc/roundcube/apache.conf':
    path    => '/etc/roundcube/apache.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('atomia/webmail/apache.conf.erb'),
  }
  ->
  file { '/etc/roundcube/config.inc.php':
    path    => '/etc/roundcube/config.inc.php',
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => template('atomia/webmail/config.inc.php.erb'),
    notify  => [ Service['apache2'] ]
  }
  ->
  if !defined(File['/etc/apache2/sites-enabled/000-default.conf']) {
    file { '/etc/apache2/sites-enabled/000-default.conf':
      ensure  => absent,
      require => Package['apache2'],
      notify  => Service['apache2'],
    }
  }

  if !defined(Service['apache2']) {
    service { 'apache2':
      ensure => running,
      enable => true,
    }
  }

}
