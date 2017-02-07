## Atomia Active Directory

### Deploys and configures Active Directory

### Variable documentation
#### domain_name: The Active Directory domain name for your environment.
#### netbios_domain_name: Short version of the domain name. Example ATOMIA
#### restore_password: Password used for Active Directory restore
#### app_password: Password for the Atomia apppooluser
#### bind_password: Password for the Atomia posixuser
#### windows_admin_password: Password for the WindowsAdmin user
#### master_ip: The ip address of this server

### Validations
##### netbios_domain_name: ^(?!:\\/*\?"<>\|)[a-zA-Z0-9]{1,15}$
##### domain_name: ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$
##### restore_password(advanced): %password
##### app_password(advanced): %password
##### bind_password(advanced): %password
##### windows_admin_password(advanced): %password
##### master_ip(advanced): %ipaddress

class atomia::active_directory (
  $domain_name            = '',
  $netbios_domain_name    = '',
  $restore_password       = '',
  $app_password           = '',
  $bind_password          = '',
  $windows_admin_password = '',
  $master_ip              = '',

) {

  File { source_permissions => ignore }

  if($::operatingsystemrelease == '2012 R2') {
    $domain_mode = 4
  } else {
    $domain_mode = 7
  }

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

    dism { 'DNS-Server-Full-Role':
      ensure => present,
      all    => true,
    } ->
    dism { 'DNS-Server-Tools':
      ensure => present,
      all    => true,
    } ->
    exec { 'enable-ad-feature':
      command  => 'Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools',
      onlyif   => 'Import-Module ServerManager; if ((Get-WindowsFeature Ad-Domain-Services).Installed) { exit 1 } else { exit 0 }',
      provider => powershell,
    } ->
    exec { 'Install AD forest':
      command  => "Import-Module ADDSDeployment; Install-ADDSForest -DomainName ${domain_name} -DomainMode ${domain_mode} -DomainNetBIOSName ${netbios_domain_name} -ForestMode ${domain_mode} -SafeModeAdministratorPassword (convertto-securestring '${restore_password}' -asplaintext -force) -Force",
      provider => powershell,
      timeout => 1000,
      onlyif   => "if((gwmi WIN32_ComputerSystem).Domain -eq '${domain_name}'){exit 1}",
      require  => Exec['enable-ad-feature'],
      logoutput => true
    } ->
    file { 'c:/install/add_users.ps1':
      ensure  => 'file',
      content => template('atomia/active_directory/add_users.ps1.erb')
    } ->
    exec { 'add-ad-users':
      command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/add_users.ps1',
    #  creates => 'C:\install\installed',
      require => [File['c:/install/add_users.ps1'], Exec['Install AD forest']],
    }

    if $::ec2_public_ipv4 {
      $ec2_hostnames = split($ec2_hostname,'[.]')
      $host_1 = $ec2_hostnames[-3]
      $ec2_domain = "${ec2_hostnames[-3]}.${ec2_hostnames[-2]}.${ec2_hostnames[-1]}"
      exec { 'add-forward-zone':
        command => "Add-DnsServerConditionalForwarderZone -Name ${ec2_domain} -MasterServers 10.0.0.2",
        provider => powershell,
        require => Exec['Install AD forest']
      }
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
