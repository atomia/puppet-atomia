## Atomia Adjoin

### Joins a server to Active Directory

### Variable documentation
#### domain_name: The domain name for the environment
#### admin_user: The admin user to use for joing Active Directory
#### admin_password: The password fpr the admin user
#### bind_user: User to use when connectiong to ldap
#### bind_password: Password for the ldap user

### Validations
##### domain_name(advanced): %url
##### admin_user(advanced): %hostname
##### admin_password(advanced): %hostname
##### bind_user(advanced): %username
##### bind_password(advanced): %password


class atomia::adjoin (
  # AD domain name
  $domain_name    = hiera('atomia::active_directory::domain_name', ''),
  $admin_user     = 'WindowsAdmin',
  $admin_password = hiera('atomia::active_directory::windows_admin_password', ''),
  $bind_user      = 'PosixGuest',
  $bind_password  = hiera('atomia::active_directory::bind_password', ''),
  ) {
    if $::operatingsystem == 'windows' {

      $ad_factfile = 'C:/ProgramData/PuppetLabs/facter/facts.d/domain_controller.txt'
      concat { $ad_factfile:
        ensure => present,
      }

      Concat::Fragment <<| tag == 'dc_ip' |>>

      $network_interface_index = hiera('atomia::windows_base::interface_index', '12')
      exec { 'set-dns':
        command  => "Set-DNSClientServerAddress -interfaceIndex ${network_interface_index} -ServerAddresses (\"${atomia::active_directory::active_directory_ip}\")",
        provider => powershell,
        unless   => "if(Get-DnsClientServerAddress -InterfaceIndex ${network_interface_index} | Where-Object {\$_.ServerAddresses -like '*${atomia::active_directory::active_directory_ip}*'}) { exit 1 }",
      }
    ->
    Host <<| |>>
  ->
  exec { 'join-domain':
    command  => "netdom join ${::hostname} /Domain:${domain_name}  /UserD:${admin_user} /PasswordD:\"${admin_password}\" /REBoot:5",
    unless   => "if((gwmi WIN32_ComputerSystem).Domain -ne \"${domain_name}\") { exit 1 }",
    provider => powershell
  }

} else {
  # Join AD on Linux
  $dc=regsubst($domain_name, '\.', ',dc=', 'G')
  $base_dn = "cn=Users,dc=${dc}"
  # Set ad_servers fact

  if $::vagrant {
    $ad_servers = 'ldap://192.168.33.10'
  } else {
    $factfile = '/etc/facter/facts.d/ad_servers.txt'

    if !defined(File['/etc/facter']) {
      file { '/etc/facter':
        ensure => directory,
      }
      file { '/etc/facter/facts.d':
        ensure  => directory,
        require => File['/etc/facter']
      }
    }

    concat { $factfile:
      ensure  => present,
      require => File['/etc/facter/facts.d']
    }

    concat::fragment {'active_directory':
      target  => $factfile,
      content => 'ad_servers=',
      tag     => 'ad_servers',
      order   => 3
    } ->
    Concat::Fragment <<| tag == 'ad_servers' |>>

  }

  if($::osfamily == 'RedHat') {

    package { 'nss-pam-ldapd': ensure => present }

    file { '/etc/nslcd.conf':
      ensure  => file,
      owner   => 'nslcd',
      group   => 'ldap',
      mode    => '0600',
      content => template('atomia/adjoin/nslcd.conf.erb'),
      require => Package['nss-pam-ldapd'],
    }
  }
  else {

    package { 'libpam-ldap': ensure => present }

    file { '/etc/ldap.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('atomia/adjoin/ldap.conf.erb'),
    }
  }

  file { '/etc/pam.d/common-account':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/atomia/adjoin/common-account',
  }

  file { '/etc/nsswitch.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/atomia/adjoin/nsswitch.conf',
  }


  file { '/etc/pam.d/common-auth':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/atomia/adjoin/common-auth',
  }

  file { '/etc/pam.d/common-session':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/atomia/adjoin/common-session',
  }

}
  }


  define atomia::adjoin::register ($content='', $res_name='', $order='10') {
    $factfile = '/etc/facter/facts.d/ad_servers.txt'

    @@concat::fragment {"active_directory_${content}_${res_name}":
      target  => $factfile,
      content => "ldap://${content} ",
      tag     => 'ad_servers',
      order   => 3
    }

  }
