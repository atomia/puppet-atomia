#
# == Class: atomia::apache_password_protect
#
# Manifest to password protect apache
#
# [$username]
# Define a username for protection
# (required)
#
# [$password]
# Defines a password for protection
# (required)
#
# === Examples
#
# class {'atomia::apache_password_protect':
#   username      => 'myUsername',
#   password      => 'myPassword',
#}


class atomia::apache_password_protect ($username, $password) {

  file { '/etc/apache2':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

if $::lsbdistrelease == '12.04' {
  file { '/etc/apache2/conf.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/apache2'],
  }
} else {
  file { '/etc/apache2/conf-available':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/apache2'],
  }
}

  htpasswd { $username:
    cryptpasswd => ht_sha1($password),
    target      => '/etc/apache2/htpasswd.conf',
    require     => File['/etc/apache2'],
  }
->
file { '/etc/apache2/htpasswd.conf':
  owner   => 'root',
  group   => 'root',
  mode    => '0444',
  require => File['/etc/apache2'],
}

if $::lsbdistrelease == '12.04' {
  file { '/etc/apache2/conf.d/passwordprotect':
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    source  => 'puppet:///modules/atomia/apache_password_protect/passwordprotect',
    require => File['/etc/apache2/conf.d'],
  }
} else {
  file { '/etc/apache2/conf-available/passwordprotect.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    source  => 'puppet:///modules/atomia/apache_password_protect/passwordprotect',
    require => File['/etc/apache2/conf-available'],
  }

  exec { '/usr/sbin/a2enconf passwordprotect.conf':
    unless  => '/usr/bin/test -f /etc/apache2/config-enabled/passwordprotect.conf',
    require => File['/etc/apache2/conf-available'],
    notify  => Service['apache2'],
  }
}

}

