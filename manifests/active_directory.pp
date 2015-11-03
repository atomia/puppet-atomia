## Atomia Active Directory

### Deploys and configures Active Directory

### Variable documentation
#### domain_name: The Active Directory domain name for your environment (example:atomia.local)
#### netbios_domain_name: Short version of the domain name (example: ATOMIA)
#### restore_password: Password used for Active Directory restore
#### app_password: Password for the Atomia apppooluser
#### bind_password: Password for the Atomia posixuser
#### windows_admin_password: Password for the WindowsAdministrator user

### Validations
##### domain_name: ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$
##### netbios_domain_name: ^[a-zA-Z0-9]+$
##### restore_password(advanced): %password
##### app_password(advanced): %password
##### bind_password(advanced): %password
##### windows_admin_password(advanced): %password

class atomia::active_directory (
  $domain_name = "",
  $netbios_domain_name = "",
  $restore_password,
  $app_password,
  $bind_password,
  $windows_admin_password,

) {


  file { "C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_ad.ps1":
    content => template('atomia/active_directory/atomia_role_active_directory.ps1.erb'),
  }


  file { 'c:/install':
    ensure => 'directory',
  }

  file { 'c:/install/sync_time.ps1':
    ensure => 'file',
    content => template('atomia/active_directory/sync_time.ps1.erb'),
    require => File['c:/install'],
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

  exec { 'sync-time':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/sync_time.ps1',
    require => File['c:/install/sync_time.ps1'],
  }
}
