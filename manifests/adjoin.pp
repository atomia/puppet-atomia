# == Class: atomia::adjoin
#
# The purpose of this class is to join the server to Active Directory.
# It works both for Windows and Linux.
#
# === Parameters
# There are two sets of parameters for Windows and Linux
#
# **Windows:
#
# **[domain_name]
# Ad domain name
# (required)
#
# **[admin_user]
# User to authenticate with
# (optional) Default: Administrator
#
# **[admin_password]
# (required)
#
# **[$dc_ip]
# Ip address of the domain controller
# (required)
#
#
# **Linux:
#
# **[base_dn]
# The base dn to bind with
# (required)
#
# **[ldap_uris]
# Comma seperated list of addresses to bind to
# (required)
#
# **[bind_user]
# (required)
#
# **[bind_password]
# (required)
#
# **[no_nscd]
# Exclude nscd if required
# (optional) Default: false

#
# === Variables
#
# === Examples
# Windows:
#```
# class {'atomia::adjoin':
#   domain_name         => "atomia.local"
#   ad_domain:          => "atomia"
#   admin_password:     => "password123"
#   dc_ip               => "8.8.8.8"
#}
#
# Linux:
#```
# class {'atomia::adjoin':
#   base_dn         => "cn=Users,dc=atomia,dc=local",
#   ldap_uris       => "ldap://9.9.9.9 ldap://9.9.9.10",
#   bind_user       => "PosixGuest",
#   bind_password   => "PosixGuestPassword"
#}
#```
# === Authors
#
# Stefan Mortensen <stefan.mortensen@atomia.com.com>
#

class atomia::adjoin (
  # AD domain name
  $domain_name    = "",
  $short_domain_name = "",
  $admin_user     = "Administrator",
  $admin_password = "",
  $dc_ip          = "",
  $base_dn        = "",
  $ldap_uris      = "",
  $bind_user      = "",
  $bind_password  = "",
  $no_nscd        = 0,) {
  if $operatingsystem == 'windows' {
    exec { 'set-dns':
      command  => "\$wmi = Get-WmiObject win32_networkadapterconfiguration -filter \"ipenabled = 'true'\"; \$wmi.SetDNSServerSearchOrder(\"$dc_ip\") ",
      provider => powershell
    }

    exec { 'join-domain':
      command  => "netdom join $hostname /Domain:$domain_name  /UserD:$admin_user /PasswordD:$admin_password /REBoot:5",
      unless   => "if((gwmi WIN32_ComputerSystem).Domain -ne \"$domain_name\") { exit 1 }",
      provider => powershell
    }
  } else {
    package { libpam-ldap: ensure => present }

    file { "/etc/pam.d/common-account":
      ensure => file,
      owner  => root,
      group  => root,
      mode   => 644,
      source => "puppet:///modules/atomia/adjoin/common-account",
    }


    if $no_nscd != 1 {
      package { nscd: ensure => present }

      file { "/etc/nscd.conf":
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => 644,
        source  => "puppet:///modules/atomia/adjoin/nscd.conf",
        require => Package["nscd"],
        notify  => Service["nscd"],
      }
      
      file { "/etc/nslcd.conf":
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => 600,
        content => template("atomia/adjoin/nslcd.conf.erb"),
        notify  => Service["nscd"],
      }

      service { nscd:
        enable    => true,
        ensure    => running,
        subscribe => File["/etc/nscd.conf"],
      }

      file { "/etc/nsswitch.conf":
        ensure => file,
        owner  => root,
        group  => root,
        mode   => 644,
        source => "puppet:///modules/atomia/adjoin/nsswitch.conf",
        notify => Service["nscd"],
      }

      file { "/etc/ldap.conf":
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => 644,
        content => template("atomia/adjoin/ldap.conf.erb"),
        notify  => Service["nscd"],
      }
    } else {
      
       service { nscd:
        enable    => false,
        ensure    => stopped,
      }
      file { "/etc/nsswitch.conf":
        ensure => file,
        owner  => root,
        group  => root,
        mode   => 644,
        source => "puppet:///modules/atomia/adjoin/nsswitch.conf",
      }

      file { "/etc/ldap.conf":
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => 644,
        content => template("atomia/adjoin/ldap.conf.erb"),
      }

    }

    file { "/etc/pam.d/common-auth":
      ensure => file,
      owner  => root,
      group  => root,
      mode   => 644,
      source => "puppet:///modules/atomia/adjoin/common-auth",
    }

    file { "/etc/pam.d/common-session":
      ensure => file,
      owner  => root,
      group  => root,
      mode   => 644,
      source => "puppet:///modules/atomia/adjoin/common-session",
    }

  }
}

