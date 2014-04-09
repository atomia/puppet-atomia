 param (
    [string]$adminUser = "Administrator",
    [string]$adminPassword = $(throw "-adminPassword is required.")
    [string]$apppoolUser = "apppooluser",
    [string]$apppoolUserPassword = $(throw "-apppoolUserPassword is required.")
    [string]$sharePath  = $(throw "-sharePath is required. Example \\storage.atomia.com\configuration\iis")
 )

$iisConfigKeyPath = $sharePath + "\iisConfigurationKey.xml"
$iisWasKeyPath = $sharePath + "\iisWasKey.xml"
$schemaPath = $sharePath + "\schema"
$adminiConfigPath = $sharePath + "\administration.config"
$appHostConfigPath = $sharePath + "\applicationHost.config"


if (!(Test-Path  $iisConfigKeyPath)) {
    c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px "iisConfigurationKey" "$iisConfigKeyPath" -pri
    c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px "iisWasKey" $iisWasKeyPath -pri

}else {
    c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisConfigurationKey" "$iisConfigKeyPath"
    c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisWasKey" "$iisConfigKeyPath"
}

if (!(Test-Path  $schemaPath)) {
    new-item -Path $schemaPath -ItemType directory
    Copy-Item C:\Windows\System32\inetsrv\config\schema\ $schemaPath
}


if (!(Test-Path  $adminiConfigPath)) {
    Copy-Item C:\Windows\System32\inetsrv\config\administration.config $adminiConfigPath
}

if (!(Test-Path  $appHostConfigPath)) {
    Copy-Item C:\Windows\System32\inetsrv\config\applicationHost.config $appHostConfigPath
    c:\install\IISSharedConfigurationEnabler.exe enable $sharePath $adminUser $adminPass 
}

c:\windows\system32\inetsrv\appcmd set config -section:system.applicationHost/log /centralLogFileMode:"CentralW3C" /centralW3CLogFile.period:"Hourly" /centralW3CLogFile.logExtFileFlags:"Date, Time, ClientIP, UserName, SiteName, Method, UriStem, UriQuery, HttpStatus, BytesSent, UserAgent, Referer, ProtocolVersion, Host" /commit:apphost

set-webconfigurationproperty /system.webServer/security/authentication/anonymousAuthentication -name userName -value ""

c:\install\RegistryUnlocker.exe u HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}


cmd /C REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" /v RunAs /d "$apppoolUser" /t REG_SZ /f 
cmd /C REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" /v EndPoints /d "ncacn_ip_tcp,0,22000" /t REG_MULTI_SZ /f
c:\install\LsaStorePrivateData set "SCM:{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" "$apppoolUserPassword" 
c:\install\RegistryUnlocker.exe l "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}"keys

netsh advfirewall firewall add rule name="RPC Mapper" dir=in action=allow profile=domain remoteip=localsubnet protocol=tcp localport=135 service=RpcSs
netsh advfirewall firewall add rule name="AHADMIN Fixed Endpoint" dir=in action=allow profile=domain remoteip=localsubnet protocol=tcp localport=22000 program=%windir%\system32\dllhost.exe
iisreset



