## Atomia Adjoin

### Joins a server to Active Directory

### Variable documentation
#### domain_name: The Active Directory domain name for the environment
#### admin_user: The admin user to use for joing Active Directory
#### admin_password: The password fpr the admin user
#### bind_user: User to use when connectiong to ldap
#### bind_password: Password for the ldap user
#### use_nss_pam_ldapd: Use nss-pam-ldapd instead of nss_ldap if joining a Linux server where the distribution supports this.

### Validations
##### domain_name(advanced): %url
##### admin_user(advanced): %hostname
##### admin_password(advanced): %hostname
##### bind_user(advanced): %username
##### bind_password(advanced): %password
##### use_nss_pam_ldapd(advanced): %int_boolean


class atomia::adjoin (
  # AD domain name
  $domain_name       = hiera('atomia::active_directory::domain_name', ''),
  $admin_user        = 'WindowsAdmin',
  $admin_password    = hiera('atomia::active_directory::windows_admin_password', ''),
  $bind_user         = 'PosixGuest',
  $bind_password     = hiera('atomia::active_directory::bind_password', '@posix123'),
  $use_nss_pam_ldapd = '1',
  ) {
  $active_directory_ip = hiera('atomia::active_directory::master_ip','')
  $active_directory_replica_ip = hiera('atomia::active_directory_replica::replica_ip','')
  if $::operatingsystem == 'windows' {

    $ad_factfile = 'C:/ProgramData/PuppetLabs/facter/facts.d/domain_controller.txt'
    concat { $ad_factfile:
      ensure => present,
    }

    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_ad.ps1':
        content => template('atomia/active_directory/atomia_role_active_directory_replica.ps1.erb'),
    }

    file {'c:/install/update_dns.ps1':
        ensure => file,
        source => 'puppet:///modules/atomia/active_directory/update_dns.ps1',
    }

    exec { 'set-dns':
        command => "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -executionpolicy remotesigned -file c:/install/update_dns.ps1 ${active_directory_ip} ${active_directory_replica_ip}",
        require => File['c:/install/update_dns.ps1'],
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
    $base_pw = $bind_password

    if $::vagrant {
      $ad_servers = 'ldap://192.168.33.10'
    } else {
      if($active_directory_replica_ip == '') {
        $ad_servers = "ldap://${active_directory_ip}"
      } else {
        $ad_servers = "ldap://${active_directory_ip} ldap://${active_directory_replica_ip}"
      }
    }

    if($::osfamily == 'RedHat' or $use_nss_pam_ldapd == '1') {

      if($::osfamily == 'RedHat') {
        $nss_package_name = 'nss-pam-ldapd'
        $nss_group = 'ldap'
      } else {
        $nss_package_name = 'libpam-ldapd'
        $nss_group = 'nslcd'
      }

      package { $nss_package_name: ensure => present }

      file { '/etc/nslcd.conf':
        ensure  => file,
        owner   => 'nslcd',
        group   => $nss_group,
        mode    => '0600',
        content => template('atomia/adjoin/nslcd.conf.erb'),
        require => Package[$nss_package_name],
        notify  => Service['nslcd'],
      }

      service { 'nslcd':
        ensure  => running,
        enable  => true,
        require => [ Package[$nss_package_name], File['/etc/nslcd.conf'] ],
      }

    } else {

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

    file { '/etc/nscd.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => template('atomia/adjoin/nscd.conf.erb'),
      }
  }
}
