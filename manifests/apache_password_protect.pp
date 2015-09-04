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
  
  file { "/etc/apache2":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => 755,
  }

  file { "/etc/apache2/conf.d":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => 755,
    require => File["/etc/apache2"],
  }


  htpasswd { $username:
    cryptpasswd => ht_sha1($password),  
    target      => '/etc/apache2/htpasswd.conf',
    require => File['/etc/apache2'],
  }  
  ->
  file { "/etc/apache2/htpasswd.conf":
    owner   => root,
    group   => root,
    mode    => 444,
    require => File["/etc/apache2"],
  }
  
  file { "/etc/apache2/conf.d/passwordprotect":
    owner   => root,
    group   => root,
    mode    => 440,
    source  => "puppet:///modules/atomia/apache_password_protect/passwordprotect",
    require => File["/etc/apache2/conf.d"],
  }
  
  if $lsbdistrelease == "14.04" {
    exec { "create_link_24":
    require => File["/etc/apache2/conf.d/passwordprotect"],
    command => "/bin/ln -s /etc/apache2/conf.d/passwordprotect /etc/apache2/conf-enabled/passwordprotect.conf",
    unless  => "/usr/bin/test -f /etc/apache2/conf-enabled/passwordprotect.conf",
    }
  }
}

