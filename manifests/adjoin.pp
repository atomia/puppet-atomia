## Atomia Adjoin

### Joins a server to Active Directory

### Variable documentation
#### domain_name: The URL of the Atomia DNS API service.
#### admin_user: A comman separated list of your nameservers (used as NS for default zones created).
#### admin_password: The username to require for accessing the service.
#### ldap_uris: The password to require for accessing the service.
#### bind_user: The hostname of the Atomia Domain Registration database.
#### no_nscd: The username for the Atomia Domain Registration database.


### Validations
##### domain_name(advanced): %url
##### admin_user(advanced): %hostname
##### admin_password(advanced): %hostname
##### ldap_uris(advanced): ^\[([a-z0-9.-]+,)*[a-z0-9.-]+\]$
##### bind_user(advanced): %username
##### no_nscd(advanced): %password


class atomia::adjoin (
  # AD domain name
  $domain_name    = hiera('atomia::active_directory::domain_name', ''),
  $admin_user     = "WindowsAdmin",
  $admin_password = hiera('atomia::active_directory::windows_admin_password', ''),
  $bind_user      = "PosixGuest",
  $bind_password  = hiera('atomia::active_directory::bind_password', ''),
  $no_nscd        = 1,) {
  if $operatingsystem == 'windows' {

    #exec { 'set-dns':
    #  command  => "\$wmi = Get-WmiObject win32_networkadapterconfiguration -filter \"ipenabled = 'true'\"; \$wmi.SetDNSServerSearchOrder(\"$dc_ip\") ",
    #  provider => powershell
    #}

    exec { 'join-domain':
      command  => "netdom join $hostname /Domain:$domain_name  /UserD:$admin_user /PasswordD:$admin_password /REBoot:5",
      unless   => "if((gwmi WIN32_ComputerSystem).Domain -ne \"$domain_name\") { exit 1 }",
      provider => powershell
    }
  } else {
    # Join AD on Linux

      $dc=regsubst($domain_name, '\.', ',dc=', 'G')
      $base_dn = "cn=Users,${$dc}"


      # Set ad_servers fact

      if $::vagrant {
        $ad_servers = "ldap://192.168.33.10"
      } else {
        $factfile = '/etc/facter/facts.d/ad_servers.txt'

        file { '/etc/facter':
          ensure => directory,
        }
        file { '/etc/facter/facts.d':
          ensure => directory,
          require => File['/etc/facter']
        }

        concat { $factfile:
          ensure => present,
          require => File['/etc/facter/facts.d']
        }
        concat::fragment {"active_directory_${content}":
            target => $factfile,
            content => "ad_servers=",
            tag => 'ad_servers',
            order => 3
          } ->
        Concat::Fragment <<| tag == 'ad_servers' |>>
      }

      package { libpam-ldap: ensure => present }

      file { "/etc/pam.d/common-account":
        ensure => file,
        owner  => root,
        group  => root,
        mode   => "644",
        source => "puppet:///modules/atomia/adjoin/common-account",
      }

     file { "/etc/nsswitch.conf":
       ensure => file,
       owner  => root,
       group  => root,
       mode   => "644",
       source => "puppet:///modules/atomia/adjoin/nsswitch.conf",
     }

     file { "/etc/ldap.conf":
       ensure  => file,
       owner   => root,
       group   => root,
       mode    => "644",
       content => template("atomia/adjoin/ldap.conf.erb"),
     }


   file { "/etc/pam.d/common-auth":
     ensure => file,
     owner  => root,
     group  => root,
     mode   => "644",
     source => "puppet:///modules/atomia/adjoin/common-auth",
   }

   file { "/etc/pam.d/common-session":
     ensure => file,
     owner  => root,
     group  => root,
     mode   => "644",
     source => "puppet:///modules/atomia/adjoin/common-session",
   }

  }
}


define atomia::adjoin::register ($content="", $order='10') {
  $factfile = '/etc/facter/facts.d/ad_servers.txt'

  @@concat::fragment {"active_directory_${content}":
      target => $factfile,
      content => "ldap://${content} ",
      tag => 'ad_servers',
      order => 3
    }

}
