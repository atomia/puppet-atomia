## Atomia Active Directory

### Deploys and configures Active Directory

### Variable documentation
#### domain_name: The Active Directory domain name for your environment.
#### netbios_domain_name: Short version of the domain name. Example ATOMIA
#### restore_password: Password used for Active Directory restore
#### app_password: Password for the Atomia apppooluser
#### bind_password: Password for the Atomia posixuser
#### windows_admin_password: Password for the WindowsAdministrator user
#### master_ip: The ip address of this server

### Validations
##### netbios_domain_name: ^[a-zA-Z0-9]+$
##### domain_name: %hostname
##### restore_password(advanced): %password
##### app_password(advanced): %password
##### bind_password(advanced): %password
##### windows_admin_password(advanced): %password
##### master_ip(advanced): .*

class atomia::active_directory (
  $domain_name            = '',
  $netbios_domain_name    = '',
  $restore_password       = '',
  $app_password           = '',
  $bind_password          = '',
  $windows_admin_password = '',
  $master_ip              = $::ipaddress,

) {

  File { source_permissions => ignore }

  # Set ip correctly when on ec2
  if !$public_ip {
    if $::ec2_public_ipv4 {
      $public_ip = $::ec2_public_ipv4
    } elsif $::ipaddress_eth0 {
      $public_ip = $::ipaddress_eth0
    }
    else {
      $public_ip = $::ipaddress
    }
  }


  if !defined(File['c:/install']) {
    file { 'c:/install':
      ensure => 'directory',
    }
  }

  file { 'c:/install/sync_time.ps1':
    ensure  => 'file',
    content => template('atomia/active_directory/sync_time.ps1.erb'),
    require => File['c:/install'],
  }

  if(!$::vagrant) {
    @@bind::zone {'domain-forward':
      zone_contact    => "contact.${domain_name}",
      zone_ns         => ["ns0.${domain_name}"],
      zone_serial     => '2012112901',
      zone_ttl        => '604800',
      zone_origin     => $domain_name,
      zone_type       => 'forward',
      zone_forwarders => $::ip_address,
    }

    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_ad.ps1':
      content => template('atomia/active_directory/atomia_role_active_directory.ps1.erb'),
    }

    exec { 'enable-ad-feature':
      command  => 'Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools',
      onlyif   => 'Import-Module ServerManager; if ((Get-WindowsFeature Ad-Domain-Services).Installed) { exit 1 } else { exit 0 }',
      provider => powershell,
    }

    exec { 'Install AD forest':
      command  => "Import-Module ADDSDeployment; Install-ADDSForest -DomainName ${domain_name} -DomainMode Win2008 -DomainNetBIOSName ${netbios_domain_name} -ForestMode Win2008 -SafeModeAdministratorPassword (convertto-securestring '${restore_password}' -asplaintext -force) -InstallDns -Force",
      provider => powershell,
      onlyif   => "if((gwmi WIN32_ComputerSystem).Domain -eq '${domain_name}'){exit 1}",
      require  => Exec['enable-ad-feature']
    }

    file { 'c:/install/add_users.ps1':
      ensure  => 'file',
      content => template('atomia/active_directory/add_users.ps1.erb'),
      require => Exec['Install AD forest']
    }
    exec { 'add-ad-users':
      command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/add_users.ps1',
      creates => 'C:\install\installed',
      require => [File['c:/install/add_users.ps1'], Exec['Install AD forest']],
    }

    $internal_zone = hiera('atomia::internaldns::zone_name')
    $internal_ip = hiera('atomia::internaldns::ip_address')

    exec { 'add-conditional-forwarder-internaldns':
      command  => "Add-DnsServerConditionalForwarderZone -Name ${internal_zone} -MasterServers ${internal_ip}",
      provider => powershell,
      require  => Exec['Install AD forest'],
      onlyif   => "if((Get-DnsServerZone -Name ${internal_zone}).ZoneName -Match '${internal_zone}') {exit 1}",
    }

  } elsif($::vagrant) {
    file { 'c:/install/add_users_vagrant.ps1':
      ensure  => 'file',
      content => template('atomia/active_directory/add_users_vagrant.ps1.erb'),
    }
    exec { 'add-ad-users-vagrant':
      command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/add_users_vagrant.ps1',
      creates => 'C:\install\installed',
      require => File['c:/install/add_users_vagrant.ps1'],
    }
  }
}