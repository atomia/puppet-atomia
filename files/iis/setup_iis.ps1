param (
    [Parameter(Mandatory=$false)]
    [String]$Action="List",
    [Parameter(Mandatory=$false)]
    [String]$UNCPath,
    [Parameter(Mandatory=$false)]
    [String]$adminUser,
    [Parameter(Mandatory=$false)]
    [String]$adminPassword    
)
 
Write-Host ""
Write-Host "                                                                       " -BackgroundColor DarkCyan
Write-Host "          IIS Shared Configuration Manager                             " -BackgroundColor DarkCyan
Write-Host "                                                                       " -BackgroundColor DarkCyan
Write-Host ""
 
#### Variables ####
$iisWASKey = "iisWASKey"
$iisConfigKey = "iisConfigurationKey"
$script:uncUser = ""
$script:uncPwd = ""
 
#### Load Web Administration DLL ####
[System.Reflection.Assembly]::LoadFrom("C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
$serverManager = New-Object Microsoft.Web.Administration.ServerManager
$config = $serverManager.GetRedirectionConfiguration()
$redirectionSection = $config.GetSection("configurationRedirection")
 
function Check-UNC()
{
    if (!($UNCPath))
    { Write-Warning "UNC Path for Shared Config is required."; exit;}
}
 
function Check-User()
{
    if (!($script:uncUser))
    {
        $script:uncUser = $adminUser
    }
 
    if (!($script:uncPwd))
    {
        $sstr = ConvertTo-SecureString $adminPassword -asplaintext -force
        $marshal = [System.Runtime.InteropServices.Marshal]
        $ptr = $marshal::SecureStringToBSTR( $sstr )
        $script:uncPwd = $marshal::PtrToStringBSTR( $ptr )
        $marshal::ZeroFreeBSTR( $ptr )
    }
}
 
function Compare-Key($KeyName)
{
    $myConfigkey = Join-Path $env:temp $KeyName
    $remotekeyPath = Join-Path $UNCPath $KeyName
 
    & $env:windir\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px $KeyName $myConfigkey -pri 
 
    if (!(Test-Path $myConfigkey ))
    {
        Write-Host "Could not export $KeyName. Check for any issues exporting Keys" -ForegroundColor DarkYellow
        return $false
    }
 
    $key1 = Get-Content $remotekeyPath
    $key2 = Get-Content $myConfigkey
 
    if (Compare-Object $key1 $key2)
    {
        return $false
    }else
    {
        return $true
    }
}
 
switch ($Action)
{
    "List" {
        Write-Host "Current Shared Configuration Setup"
        Write-Host ""
        if ($redirectionSection.Attributes["enabled"].Value -eq "true")
        {
            Write-Host "Shared Configuration is Enabled"
            Write-Host "Config Path: " $redirectionSection.Attributes["path"].Value
            Write-Host "User Name: " $redirectionSection.Attributes["userName"].Value
 
            $UNCPath = $redirectionSection.Attributes["path"].Value
 
            if (Compare-Key $iisWASKey )
            { Write-Host "$iisWASKey Check: In sync with Farm"}else
            { Write-Host "$iisWASKey Check: NOT in sync with Farm" -ForegroundColor DarkYellow}
 
            if (Compare-Key $iisConfigKey  )
            { Write-Host "$iisConfigKey Check: In sync with Farm"}else
            { Write-Host "$iisConfigKey Check: NOT in sync with Farm" -ForegroundColor DarkYellow}
 
        }else{
 
            Write-Host "Shared Configuration is NOT Enabled"
        }
    }
    "Enable" {
        Write-Host "Enabling Shared Configuration"
        Write-Host ""
 
        # Ensure UNC was provided
        Check-UNC
 
        # If Service Account isn't hard coded, prompt for it
        Check-User
 
        # Import iisWASKey if needed
        if (Compare-Key $iisWASKey )
        { Write-Host "$iisWASKey Check: In sync with Farm"}else
        {
            Write-Host "$iisWASKey Check: NOT in sync with Farm, updating..."
            $wasKey = Join-Path $UNCPath $iisWASKey
            & $env:windir\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi "iisWasKey" $wasKey -exp
        }
 
        # Import iisConfigKey if needed
        if (Compare-Key $iisConfigKey  )
        { Write-Host "$iisConfigKey Check: In sync with Farm"}else
        {
            Write-Host "$iisConfigKey Check: NOT in sync with Farm, updating..."
            $configKey = Join-Path $UNCPath $iisConfigKey
            & $env:windir\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -pi $iisConfigKey $configKey -exp
        }
 
        # Update Shared Config Settings
        $redirectionSection.Attributes["enabled"].Value = "true"
        $redirectionSection.Attributes["path"].Value = $UNCPath
        $redirectionSection.Attributes["userName"].Value = $script:uncUser
        $redirectionSection.Attributes["password"].Value = $script:uncPwd
        $serverManager.CommitChanges()
        Write-Host ""
        Write-Host "Shared Configuration Enabled using $uncpath"
    }
    "Disable" {
        Write-Host "Disable Shared Configuration"
        Write-Host ""
 
        if ($redirectionSection.Attributes["enabled"].Value -eq "true")
        {
            $redirectionSection.Attributes["enabled"].Value = "false"
            $serverManager.CommitChanges()
 
            Write-Host "Shared Configuration Disabled"
        }else
        {
            Write-Host "Shared Configuration is NOT Enabled"
        }
    }
    "Export" {
        Write-Host "Export Shared Configuration"
        Write-Host ""
 
        Check-UNC
 
        ### Copy applicationHost.config
        $appConfig = Join-Path $UNCPath "applicationHost.config"
        cpi $env:windir\system32\inetsrv\config\applicationHost.config $appConfig
 
        ### Copy administration.config
        $adminConfig = Join-Path $UNCPath "administration.config"
        cpi $env:windir\system32\inetsrv\config\administration.config $adminConfig
 
        ### Export Keys
        $wasKey = Join-Path $UNCPath $iisWASKey
        & $env:windir\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px $iisWASKey $wasKey -pri 
 
        $ConfigKey = Join-Path $UNCPath $iisConfigKey
        & $env:windir\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -px $iisConfigKey $ConfigKey -pri 
 
    }
    default {"$Action is not a valid action. Exiting. "; exit}
 }
 
Write-Host ""
Write-Host "                                                                       " -BackgroundColor DarkCyan

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



