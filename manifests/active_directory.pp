## Atomia Active Directory

### Deploys and configures Active Directory

### Variable documentation
#### domain_name: The Active Directory domain name for your environment (example:atomia.local)
#### netbios_domain_name: Short version of the domain name (example: ATOMIA)
#### restore_password: Password used for Active Directory restore
#### app_password: Password for the Atomia apppooluser
#### bind_password: Password for the Atomia posixuser
#### windows_admin_password: Password for the WindowsAdministrator user
#### is_master: Specify if the server is master or slave

### Validations
##### domain_name: ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$
##### netbios_domain_name: ^[a-zA-Z0-9]+$
##### restore_password(advanced): %password
##### app_password(advanced): %password
##### bind_password(advanced): %password
##### windows_admin_password(advanced): %password
##### is_master(advanced): %hide

class atomia::active_directory (
  $domain_name = "",
  $netbios_domain_name = "",
  $restore_password,
  $app_password,
  $bind_password,
  $windows_admin_password,
  $is_master = 1,

) {

  # Set ip correctly when on ec2
  if $ec2_public_ipv4 {
    $public_ip = $ec2_public_ipv4
  } else {
    $public_ip = $ipaddress_eth0
  }

  atomia::adjoin::register{ "${::fqdn}": content => $public_ip}

  file { 'c:/install':
    ensure => 'directory',
  }

  file { 'c:/install/sync_time.ps1':
    ensure => 'file',
    content => template('atomia/active_directory/sync_time.ps1.erb'),
    require => File['c:/install'],
  }

  if($is_master == 1) {
    atomia::active_directory::store_ip{ "${::fqdn}": content => $public_ip}
    @@host { 'domain-name-host':
    		name		=> "$domain_name",
    		ip	=> "${public_ip}"
  	}

    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_ad.ps1':
      content => template('atomia/active_directory/atomia_role_active_directory.ps1.erb'),
    }

    exec { "enable-ad-feature":
      command   => "Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools",
      unless    => "Import-Module ServerManager; if (@(Get-WindowsFeature AD-Domain-Services | ?{$_.Installed -match 'false'}).count -eq 0) { exit 1 }",
      provider  => powershell,
    }

    exec { 'Install AD forest':
      command => "Import-Module ADDSDeployment; Install-ADDSForest -DomainName ${domain_name} -DomainMode Win2008 -DomainNetBIOSName ${netbios_domain_name} -ForestMode Win2008 -SafeModeAdministratorPassword (convertto-securestring '${restore_password}' -asplaintext -force) -InstallDns -Force",
      provider    => powershell,
      onlyif      => "if((gwmi WIN32_ComputerSystem).Domain -eq '${domain_name}'){exit 1}",
      require   => Exec["enable-ad-feature"]
    }

    if($::vagrant){
  	  file { 'c:/install/add_users_vagrant.ps1':
  	    ensure => 'file',
  	    content => template('atomia/active_directory/add_users_vagrant.ps1.erb'),
  	  }
      exec { 'add-ad-users-vagrant':
        command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/add_users_vagrant.ps1',
        creates => 'C:\install\installed',
        require => File['c:/install/add_users_vagrant.ps1'],
      }

    } else {
  	  file { 'c:/install/add_users.ps1':
  	    ensure => 'file',
  	    content => template('atomia/active_directory/add_users.ps1.erb'),
        require => Exec['Install AD forest']
  	  }
  	  exec { 'add-ad-users':
  	    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/add_users.ps1',
  	    creates => 'C:\install\installed',
  	    require => [File['c:/install/add_users.ps1'], Exec['Install AD forest']],
  	  }
    }

  }
  else
  {
    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_ad.ps1':
      content => template('atomia/active_directory/atomia_role_active_directory_replica.ps1.erb'),
    }

    $ad_factfile = 'C:/ProgramData/PuppetLabs/facter/facts.d/domain_controller.txt'
    concat { $ad_factfile:
      ensure => present,
    }

    Concat::Fragment <<| tag == 'dc_ip' |>>

    exec { 'set-dns':
      command => "Set-DNSClientServerAddress -interfaceIndex 12 -ServerAddresses (\"$active_directory_ip\")",
      provider => powershell,
      unless => 'if(Get-DnsClientServerAddress -InterfaceIndex 12 | Where-Object {$_.ServerAddresses -like "*${active_directory_ip}*"}) { exit 1 }',
    }
    ->
    Host <<| |>>
    ->
    exec { "enable-ad-feature":
      command   => "Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools",
      unless    => "Import-Module ServerManager; if (@(Get-WindowsFeature AD-Domain-Services | ?{$_.Installed -match 'false'}).count -eq 0) { exit 1 }",
      provider  => powershell,
    }

    #$secpasswd = ConvertTo-SecureString '${windows_admin_password}' -AsPlainText -Force;$credentials = New-Object System.Management.Automation.PSCredential ('${netbios_domain_name\\WindowsAdmin}', $secpasswd);Import-Module ADDSDeployment;
    exec { 'Install AD replica':
      command     => "Import-Module ADDSDeployment; Install-ADDSDomainController -DomainName ${domain_name}  -InstallDns -Force -SiteName 'Default-First-Site-Name' -SafeModeAdministratorPassword (convertto-securestring '${restore_password}' -asplaintext -Force) -CreateDnsDelegation:\$false",
      provider    => powershell,
      unless   => "if((gwmi WIN32_ComputerSystem).Domain -ne \"$domain_name\") { exit 1 }",
      require   => Exec['enable-ad-feature']
    }
  }


  exec { 'sync-time':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/sync_time.ps1',
    require => File['c:/install/sync_time.ps1'],
  }
}

define atomia::active_directory::store_ip ($content="", $order='10') {
  $factfile = 'C:/ProgramData/PuppetLabs/facter/facts.d/domain_controller.txt'

  @@concat::fragment {"active_directory_ip_${content}":
      target => $factfile,
      content => "active_directory_ip=${content} ",
      tag => 'dc_ip',
      order => 3
    }

}
