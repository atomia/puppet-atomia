## Atomia IIS cluster node

### Deploys and configures a IIS cluster node for hosting customer websites.

### Variable documentation
#### sharePath: The path to the IIS shared configuration folder.
#### cluster_ip: The virtual IP of the IIS cluster.

### Validations
##### sharePath(advanced): ^[a-z0-9.:_\\-]+$
##### cluster_ip: %ip

class atomia::iis(
	$sharePath = '\\storage\configshare\iis',
	$cluster_ip = ""
){

	$adminUser = "WindowsAdmin"
	$adminPassword = hiera('atomia::active_directory::windows_admin_password', '')
	$apppoolUser =	"apppooluser"
	$apppoolUserPassword = hiera('atomia::windows_base::app_password', '')
	$adDomain = hiera('atomia::windows_base::ad_domain', '')

	$dism_features_to_enable = [
		'NetFx3', 'IIS-WebServerRole', 'IIS-WebServer', 'IIS-CommonHttpFeatures', 'IIS-Security', 'IIS-RequestFiltering',
		'IIS-StaticContent', 'IIS-DefaultDocument', 'IIS-ApplicationDevelopment', 'IIS-NetFxExtensibility', 'IIS-ASPNET',
		'IIS-ASP', 'IIS-CGI', 'IIS-ServerSideIncludes', 'IIS-CustomLogging', 'IIS-BasicAuthentication', 'IIS-WebServerManagementTools',
		'IIS-ManagementConsole',
	]

	dism { $dism_features_to_enable: ensure => present, all => true }

	if !defined(File['c:/install']) {
		file { 'c:/install': ensure => 'directory' }
	}

	file { 'c:/install/IISSharedConfigurationEnabler.exe':
		ensure => 'file',
		source => "puppet:///modules/atomia/iis/IISSharedConfigurationEnabler.exe",
	mode	 => "0777",
		require => File['c:/install'],
	}

	file { 'c:/install/LsaStorePrivateData.exe':
		ensure => 'file',
		source => "puppet:///modules/atomia/iis/LsaStorePrivateData.exe",
	mode	 => "0777",
		require => File['c:/install'],
	}

	file { 'c:/install/RegistryUnlocker.exe':
		ensure => 'file',
		source => "puppet:///modules/atomia/iis/RegistryUnlocker.exe",
	mode	 => "0777",
		require => File['c:/install'],
	} 

	file { 'c:/install/setup_iis.ps1':
		ensure => 'file',
		source => "puppet:///modules/atomia/iis/setup_iis.ps1",
		require => File['c:/install'],
	}

	exec { 'setup_iis':
		provider => powershell,
		command => "c:/install/setup_iis.ps1 -adminUser \"${adDomain}\\${adminUser}\" -adminPassword \"$adminPassword\" -apppoolUser \"${adDomain}\\${apppoolUser}\" -apppoolUserPassword \"$apppoolUserPassword\" -sharePath \"$sharePath\"",
		require => [File["c:/install/setup_iis.ps1"], File["c:/install/IISSharedConfigurationEnabler.exe"], File["c:/install/LsaStorePrivateData.exe"], File["c:/install/RegistryUnlocker.exe"]],
		creates => 'c:\windows\install\installed'
	}
}
