## Atomia IIS cluster node

### Deploys and configures a IIS cluster node for hosting customer websites.

### Variable documentation
#### sharePath: The path to the IIS shared configuration folder. Leave blank if using the default GlusterFS setup
#### cluster_ip: The virtual IP of the IIS cluster.
#### first_node: The hostname of the first node in the cluster

### Validations
##### sharepath(advanced): .*
##### cluster_ip: %ip
##### first_node(advanced): .*

class atomia::iis(
  $sharepath  = '',
  $cluster_ip = '',
  $first_node = $fqdn
){

  $adminuser     = 'WindowsAdmin'
  $adminpassword = hiera('atomia::active_directory::windows_admin_password', '')
  $addomain      = hiera('atomia::active_directory::domain_name', '')

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
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/IISSharedConfigurationEnabler.exe',
    mode    => '0777',
    require => File['c:/install'],
  }

  file { 'c:/install/LsaStorePrivateData.exe':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/LsaStorePrivateData.exe',
    mode    => '0777',
    require => File['c:/install'],
  }

  file { 'c:/install/RegistryUnlocker.exe':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/RegistryUnlocker.exe',
    mode    => '0777',
    require => File['c:/install'],
  }

  file { 'c:/install/setup_iis.ps1':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/setup_iis.ps1',
    require => File['c:/install'],
  }

  if $sharepath == '' {
    $internal_zone = hiera('atomia::internaldns::zone_name','')
    $realsharepath = '\\gluster' + $internal_zone + '\configshare\iis'
  }
  else
  {
    $realsharepath = $sharepath
  }

  exec { 'setup_iis':
    provider => powershell,
    command  => "c:/install/setup_iis.ps1 -Action 'enable' -UNCPath '${realsharepath}' -adminUser '${addomain}\\WindowsAdmin' -adminPassword '${adminpassword}'",
    require  => [Dism[$dism_features_to_enable], File['c:/install/setup_iis.ps1'], File['c:/install/IISSharedConfigurationEnabler.exe'], File['c:/install/LsaStorePrivateData.exe'], File['c:/install/RegistryUnlocker.exe']],
    creates  => 'c:\windows\install\installed'
  }

  file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_iis.txt':
    content => 'atomia_role_1=iis',
  }
}
