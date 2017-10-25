param (
    [Parameter(Mandatory=$true)]
    [String]$adminUser,
    [Parameter(Mandatory=$true)]
    [String]$adminPassword
)
 
# making registry changes
cmd /C c:\install\RegistryUnlocker.exe u "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}"
cmd /C REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" /v RunAs /d "$adminUser" /t REG_SZ /f 
cmd /C REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" /v EndPoints /d "ncacn_ip_tcp,0,22000" /t REG_MULTI_SZ /f
cmd /C c:\install\LsaStorePrivateData set "SCM:{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" "$adminPassword" 
cmd /C c:\install\RegistryUnlocker.exe l "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9fa5c497-f46d-447f-8011-05d03d7d7ddc}" keys