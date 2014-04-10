 param (
    [string]$adminUser = "Administrator",
    [string]$adminPassword = $(throw "-adminPassword is required."),
    [string]$apppoolUser = "apppooluser",
    [string]$apppoolUserPassword = $(throw "-apppoolUserPassword is required."),
    [string]$sharePath  = $(throw "-sharePath is required. Example \\storage.atomia.com\configuration\iis")
 )

$iisConfigKeyPath = $sharePath + "\iisConfigurationKey.xml"
$iisWasKeyPath = $sharePath + "\iisWasKey.xml"
$schemaPath = $sharePath + "\schema"
$adminiConfigPath = $sharePath + "\administration.config"
$appHostConfigPath = $sharePath + "\applicationHost.config"
if (!(Test-Path  "c:\install\installed")) {

    if (!(Test-Path  $iisConfigKeyPath)) {
        "Exporing keys"
        c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px "iisConfigurationKey" "$iisConfigKeyPath" -pri
        c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px "iisWasKey" $iisWasKeyPath -pri
        c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisConfigurationKey" "$iisConfigKeyPath"
        c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisWasKey" "$iisConfigKeyPath"

    }else {
        "Importing Keys"
        c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisConfigurationKey" "$iisConfigKeyPath"
        c:\windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisWasKey" "$iisConfigKeyPath"
    }

    if (!(Test-Path  $schemaPath)) {
        "Copying schema"
        new-item -Path $schemaPath -ItemType directory
        Copy-Item C:\Windows\System32\inetsrv\config\schema\* $schemaPath
    }


    if (!(Test-Path  $adminiConfigPath)) {
        "Copying admin"
        Copy-Item C:\Windows\System32\inetsrv\config\administration.config $adminiConfigPath
    }

    if (!(Test-Path  $appHostConfigPath)) {
        "Copying apphost"
        Copy-Item C:\Windows\System32\inetsrv\config\applicationHost.config $appHostConfigPath
    
    }

    "Enable shared config"

    c:\install\IISSharedConfigurationEnabler.exe enable "$sharePath" "$apppoolUser" "$apppoolUserPassword"

    "Logging config"
    c:\windows\system32\inetsrv\appcmd set config -section:system.applicationHost/log /centralLogFileMode:"CentralW3C" /centralW3CLogFile.period:"Hourly" /centralW3CLogFile.logExtFileFlags:"Date, Time, ClientIP, UserName, SiteName, Method, UriStem, UriQuery, HttpStatus, BytesSent, UserAgent, Referer, ProtocolVersion, Host" /commit:apphost

    "Enable anon auth"
    set-webconfigurationproperty /system.webServer/security/authentication/anonymousAuthentication -name userName -value ""

    # making registry changes
    cmd /C c:\install\RegistryUnlocker.exe u "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}"
    cmd /C REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" /v RunAs /d "$apppoolUser" /t REG_SZ /f 
    cmd /C REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" /v EndPoints /d "ncacn_ip_tcp,0,22000" /t REG_MULTI_SZ /f
    cmd /C c:\install\LsaStorePrivateData set "SCM:{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" "$apppoolUserPassword" 
    cmd /C c:\install\RegistryUnlocker.exe l "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}"keys

    netsh advfirewall firewall add rule name="RPC Mapper" dir=in action=allow profile=domain remoteip=localsubnet protocol=tcp localport=135 service=RpcSs
    netsh advfirewall firewall add rule name="AHADMIN Fixed Endpoint" dir=in action=allow profile=domain remoteip=localsubnet protocol=tcp localport=22000 program=%windir%\system32\dllhost.exe
    iisreset

    New-Item -ItemType directory -Path C:\install\installed

}

