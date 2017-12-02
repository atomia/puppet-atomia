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
  ) {

  $adminuser     = 'WindowsAdmin'
  $adminpassword = hiera('atomia::active_directory::windows_admin_password', '')
  $addomain      = hiera('atomia::active_directory::netbios_domain_name', '')

  if $sharepath == '' {
    $internal_zone = hiera('atomia::internaldns::zone_name','')
    $realsharepath = "\\gluster.${internal_zone}\\configshare\\iis"
  }
  else
  {
    $realsharepath = "${sharepath}"
  }

  File { source_permissions => ignore }

  $dism_features_to_enable = [
    'NetFx3', 'IIS-WebServerRole', 'IIS-WebServer', 'IIS-CommonHttpFeatures', 'IIS-Security', 'IIS-RequestFiltering',
    'IIS-StaticContent', 'IIS-DefaultDocument', 'IIS-ApplicationDevelopment', 'IIS-NetFxExtensibility', 'IIS-ASPNET', 'IIS-ASPNET45',
    'IIS-ASP', 'IIS-CGI', 'IIS-ServerSideIncludes', 'IIS-CustomLogging', 'IIS-BasicAuthentication', 'IIS-WebServerManagementTools',
    'IIS-ManagementConsole',
  ]

  dism { $dism_features_to_enable: ensure => present, all => true }
  ->
  if !defined(File['c:/install']) {
    file { 'c:/install': ensure => 'directory' }
  }
  ->
  file { 'c:/install/IISSharedConfigurationEnabler.exe':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/IISSharedConfigurationEnabler.exe',
    mode    => '0777',
    require => File['c:/install'],
  }
  ->
  file { 'c:/install/LsaStorePrivateData.exe':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/LsaStorePrivateData.exe',
    mode    => '0777',
    require => File['c:/install'],
  }
  ->
  file { 'c:/install/RegistryUnlocker.exe':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/RegistryUnlocker.exe',
    mode    => '0777',
    require => File['c:/install'],
  }
  ->
  file { 'c:/install/setup_iis.ps1':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/setup_iis.ps1',
    require => File['c:/install'],
  }
  ->
  file { 'c:/install/setup_registry.ps1':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/iis/setup_registry.ps1',
    require => File['c:/install'],
  }
  ->
  exec { 'export_iis_config':
    provider => powershell,
    command  => "c:/install/setup_iis.ps1 -Action 'export' -UNCPath '${realsharepath}' -adminUser '${addomain}\\${adminuser}' -adminPassword '${adminpassword}'",
    require  => [Dism[$dism_features_to_enable], File['c:/install/setup_iis.ps1'], File['c:/install/IISSharedConfigurationEnabler.exe'], File['c:/install/LsaStorePrivateData.exe'], File['c:/install/RegistryUnlocker.exe']],
    creates  => "${realsharepath}\\applicationHost.config"
  }
  ->
  exec { 'enable_iis_sharedconfig':
    provider => powershell,
    command  => "c:/install/setup_iis.ps1 -Action 'enable' -UNCPath '${realsharepath}' -adminUser '${addomain}\\${adminuser}' -adminPassword '${adminpassword}'",
    onlyif   => "C:\\Windows\\System32\\cmd.exe /c 'if exist ${realsharepath}\\applicationHost.config (exit 0) else (exit 1)'",
    creates  => 'c:\install\2_iis_sharedconfig_enabled.txt'
  }
  ->
  exec { 'setup_iis_logging':
    provider => powershell,
    command  => 'c:\windows\system32\inetsrv\appcmd set config -section:system.applicationHost/log /centralLogFileMode:"CentralW3C" /centralW3CLogFile.period:"Hourly" /centralW3CLogFile.logExtFileFlags:"Date, Time, ClientIP, UserName, SiteName, Method, UriStem, UriQuery, HttpStatus, BytesSent, UserAgent, Referer, ProtocolVersion, Host" /commit:apphost',
    creates  => 'c:\install\3_central_iis_logging_enabled.txt'
  }
  ->
  exec { 'setup_registry':
    provider => powershell,
    command  => "c:/install/setup_registry.ps1 -adminUser '${addomain}\\${adminuser}' -adminPassword '${adminpassword}'",
    creates  => 'C:\install\setup_registry.txt',
  }
  ->
  exec { 'enable_anonymous_auth':
    provider => powershell,
    command  => 'Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name userName -Value "" -PSPath IIS:\ -Location "Default Web Site/$iisAppName"',
    creates  => 'c:\install\5_anon_auth_enabled',
  }

  exec { 'open_firewall_135_port':
    provider => powershell,
    command  => 'netsh advfirewall firewall add rule name="RPC Mapper" dir=in action=allow protocol=tcp localport=135',
  }

  exec { 'open_firewall_22000_port':
    provider => powershell,
    command  => 'netsh advfirewall firewall add rule name="AHADMIN Fixed Endpoint" dir=in action=allow protocol=tcp localport=22000',
  }

}
