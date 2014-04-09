class atomia::iis(
	$adminUser = hiera('atomia::adjoin::admin_user', 'Administrator'),
	$adminPassword = hiera('atomia::adjoin::admin_password', 'Administrator'),
	$apppoolUser = "apppooluser",
	$apppoolUserPassword = hiera('app_password', ''),	
	$sharePath,
){

	dism { 'NetFx3': ensure => present, all => true }
	dism { 'IIS-WebServerRole': ensure => present, all => true  }
	dism { 'IIS-WebServer': ensure => present, all => true  }
	dism { 'IIS-CommonHttpFeatures': ensure => present, all => true  }
	dism { 'IIS-Security': ensure => present, all => true  }
	dism { 'IIS-RequestFiltering': ensure => present, all => true  }
	dism { 'IIS-StaticContent': ensure => present, all => true  }
	dism { 'IIS-DefaultDocument': ensure => present, all => true  }
	dism { 'IIS-ApplicationDevelopment': ensure => present, all => true  }
	dism { 'IIS-NetFxExtensibility': ensure => present, all => true  }
	dism { 'IIS-ASPNET': ensure => present, all => true }
	dism { 'IIS-ASP': ensure => present, all => true  }
	dism { 'IIS-CGI': ensure => present, all => true  }
	dism { 'IIS-ServerSideIncludes': ensure => present, all => true  }
	dism { 'IIS-CustomLogging': ensure => present, all => true  }
	dism { 'IIS-BasicAuthentication': ensure => present, all => true  }
	dism { 'IIS-WebServerManagementTools': ensure => present, all => true  }
	dism { 'IIS-ManagementConsole': ensure => present, all => true  }

	# Deploy installation folder 
	file { 'c:/install': ensure => 'directory' }

  file { 'c:/install/IISSharedConfigurationEnabler.exe':
    ensure => 'file',
    source => "puppet:///modules/atomia/iis/IISSharedConfigurationEnabler.exe",
    require => File['c:/install'],
  }

  file { 'c:/install/LsaStorePrivateData.exe':
    ensure => 'file',
    source => "puppet:///modules/atomia/iis/LsaStorePrivateData.exe",
    require => File['c:/install'],
  }

  file { 'c:/install/RegistryUnlocker.exe':
    ensure => 'file',
    source => "puppet:///modules/atomia/iis/RegistryUnlocker.exe",
    require => File['c:/install'],
  }  

  file { 'c:/install/setup_iis.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/iis/setup_iis.ps1",
    require => File['c:/install'],
  }  

  exec { 'setup_iis':
  	command => "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/setup_iis.ps1 -adminUser $adminUser -adminPassword $adminPassword -apppoolUser $apppoolUser -apppoolUserPassword $apppoolUserPassword -sharePath $sharePath",
  	require => [File["c:/install/setup_iis.ps1"], File["c:/install/IISSharedConfigurationEnabler.exe"], File["c:/install/LsaStorePrivateData.exe"], File["c:/install/RegistryUnlocker.exe"]],
  	creates => 'c:\windows\install\installed'
  }

}
