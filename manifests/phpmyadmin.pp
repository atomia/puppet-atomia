class atomia::phpmyadmin (
  $mysql_host
){

  if $::lsbdistrelease == '14.04' {
    $php_version            = 'php5'
    $php_path               = '/etc/php5/apache2/php.ini'
  } else {
    $php_version            = 'php7.0'
    $php_path               = '/etc/php/7.0/apache2/php.ini'
  }

  package { 'phpmyadmin': ensure => present }
  package { 'apache2': ensure => present }
  package { "libapache2-mod-${php_version}": ensure => present }

  file { '/etc/phpmyadmin/config.inc.php':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/phpmyadmin/config.inc.php'),
    require => Package['phpmyadmin'],
  }

  file { '/etc/apache2/sites-available/phpmyadmin.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/atomia/phpmyadmin/default',
    require => Package['apache2'],
  }

  exec { "/usr/sbin/a2ensite phpmyadmin.conf":
    unless  => '/usr/bin/test -f /etc/apache2/sites-enabled/phpmyadmin.conf',
    require => [File['/etc/apache2/sites-available/phpmyadmin.conf'], Package['apache2']],
    notify  => Exec['force-reload-apache-phpmyadmin'],
  }

  if !defined(File['/etc/apache2/sites-enabled/000-default.conf']) {
    file { '/etc/apache2/sites-enabled/000-default.conf':
      ensure  => absent,
      require => Package['apache2'],
      notify  => Service['apache2'],
    }
  }

  exec { 'force-reload-apache-phpmyadmin':
    refreshonly => true,
    before      => Service['apache2'],
    command     => '/etc/init.d/apache2 force-reload',
  }

  exec { "/usr/sbin/a2enmod ${php_version}":
    unless  => "/usr/bin/test -f /etc/apache2/mods-enabled/${php_version}.load",
    require => Package["libapache2-mod-${php_version}"],
    notify  => Exec['force-reload-apache-phpmyadmin'],
  }

  service { 'apache2':
    ensure => running,
  }
}
