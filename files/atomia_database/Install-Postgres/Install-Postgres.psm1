#################################################################################  
##  
## PostgreSQL unattended install 
## Author: Stefan Prodan   
## Date : 16 Oct 2014  
## Company: VeriTech.io    
################################################################################

Function Install-Postgres
{
<# 
 
.SYNOPSIS 
PostgreSQL unattended install
 
.DESCRIPTION
PostgreSQL unattended install script does the following: 
creates a local windows user that PostgreSQL will use, 
the password use for the creation of this account will be the same as the one used for PostgreSQL's postgres superuser account, 
creates postgres user profile,
downloads the PostgreSQL installer provided by EnterpriseDB, 
installs Postgres unattended using the supplied parameters, 
sets postgres windows user as owner of Postgres files and folders, 
sets Postgres windows service to run under postgres local user, 
creates pgpass.conf file in AppData, 
copies configuration files to data directory, 
opens the supplied port that PostgreSQL will use in the Windows Firewall.
 
.PARAMETER User     
Local windows user that runs pg windows service
 
.PARAMETER Password 
Windows user password as well as pg superuser password 
 
.PARAMETER InstallerUrl 
Default value 'http://get.enterprisedb.com/postgresql/postgresql-9.3.5-1-windows-x64.exe'
 
.PARAMETER InstallPath 
Default value "C:\Program Files\PostgreSQL\9.3"

.PARAMETER DataPath 
Default value "C:\Program Files\PostgreSQL\9.3\data"

.PARAMETER Locale 
Default value "English, United States"

.PARAMETER Port 
Default value 5432

.PARAMETER ServiceName 
Default value "postgresql"
 
.EXAMPLE 
Install-Postgres -User postgres -Password ChangeMe!
 
.NOTES 
You need to have administrative permissions to run this script. 
 
#> 

    Param
    (
	    [Parameter(Mandatory=$true)]
	    [Alias('User')][String]$pgUser="postgres",

	    [Parameter(Mandatory=$true)]
	    [Alias('Password')][String]$pgPassword,

	    [Parameter(Mandatory=$false)]
	    [Alias('InstallerUrl')][String]$pgKitSource="http://get.enterprisedb.com/postgresql/postgresql-9.3.5-1-windows-x64.exe",

	    [Parameter(Mandatory=$false)]
	    [Alias('InstallPath')][String]$pgInstallPath="C:\Program Files\PostgreSQL\9.3",

	    [Parameter(Mandatory=$false)]
	    [Alias('DataPath')][String]$pgDataPath="C:\Program Files\PostgreSQL\9.3\data",

	    [Parameter(Mandatory=$false)]
	    [Alias('Locale')][String]$pgLocale="English, United States",

	    [Parameter(Mandatory=$false)]
	    [Alias('Port')][int]$pgPort=5432,

	    [Parameter(Mandatory=$false)]
	    [Alias('ServiceName')][String]$pgServiceName="postgresql"
    )

    $pgKit = "$PSScriptRoot\postgresql.exe";
    $pgConfigSource = "$PSScriptRoot\Config";
    $pgPassPath = "C:\Users\$pgUser\AppData\Roaming\postgresql";

    Write-Host "Creating local user $pgUser";

    try
    {
        New-LocalUser $pgUser $pgPassword;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }

    $script:nativeMethods = @();
    if (-not ([System.Management.Automation.PSTypeName]'NativeMethods').Type)
    {
        Register-NativeMethod "userenv.dll" "int CreateProfile([MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,`
         [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,`
         [Out][MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath, uint cchProfilePath)";

        Add-NativeMethods;
    }

    $localUser = New-Object System.Security.Principal.NTAccount("postgres");
    $userSID = $localUser.Translate([System.Security.Principal.SecurityIdentifier]);
    $sb = new-object System.Text.StringBuilder(260);
    $pathLen = $sb.Capacity;

    Write-Host "Creating user profile for $pgUser";

    try
    {
        [NativeMethods]::CreateProfile($userSID.Value, $pgUser, $sb, $pathLen) | Out-Null;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Installing Postgres in $pgInstallPath";

    try
    {
        Start-PostgresInstall $pgKitSource $pgKit $pgInstallPath $pgDataPath $pgLocale $pgPort $pgServiceName $pgUser $pgPassword;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Grant full control of $pgInstallPath for user $pgUser";

    try
    {
        Set-DirOwner $pgInstallPath $pgUser;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Creating pgpass.conf in $pgPassPath";

    try
    {
        New-PgPass $pgPassPath $pgUser $pgPassword;
        Set-Owner $pgPassPath $pgUser;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Copying config files to $pgDataPath";

    try
    {
        Copy-Configs $pgConfigSource $pgDataPath;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Creating firewall rule for port $pgPort";

    try
    {
        Open-Port $pgServiceName $pgPort;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Changing $serviceName windows service user to $pgUser";

    try
    {
        Set-ServiceOwner $pgServiceName $pgUser $pgPassword;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }

    Write-Host "Postgres has been installed";
}


function New-LocalUser($userName, $password)
{
    $system = [ADSI]"WinNT://$env:COMPUTERNAME";
    $user = $system.Create("user",$userName);
    $user.SetPassword($password);
    $user.SetInfo();

    $flag=$user.UserFlags.value -bor 0x10000;
    $user.put("userflags",$flag);
    $user.SetInfo();

    $group = [ADSI]("WinNT://$env:COMPUTERNAME/Users");
    $group.PSBase.Invoke("Add", $user.PSBase.Path);
}

function Register-NativeMethod([string]$dll, [string]$methodSignature)
{
    $script:nativeMethods += [PSCustomObject]@{ Dll = $dll; Signature = $methodSignature; }
}

function Add-NativeMethods()
{
    $nativeMethodsCode = $script:nativeMethods | % { "
        [DllImport(`"$($_.Dll)`")]
        public static extern $($_.Signature);
    " }

    Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public static class NativeMethods {
            $nativeMethodsCode
        }
"@
}

function Start-PostgresInstall($installerUrl, $installerPath, $installPath, $dataPath, $locale, $port, $serviceName, $user, $password)
{
    #create folders
    New-Item -ItemType Directory -Force -Path $installPath;
    New-Item -ItemType Directory -Force -Path $dataPath;

    # download pg installer
    Invoke-WebRequest $installerUrl -OutFile $installerPath;


    # run pg installer
    Start-Process $installerPath -ArgumentList "--mode unattended", "--unattendedmodeui none",`
     "--prefix `"$installPath`"", "--datadir `"$dataPath`"", "--locale `"$locale`"", "--superpassword `"$password`"",`
     "--serverport $port", "--servicename `"$serviceName`"", "--serviceaccount `"$user`"", "--servicepassword `"$password`""`
     -Wait;
 }

 function Set-DirOwner($path, $userName)
{
    $acl = Get-Acl $path;
    $aclDef = "$env:COMPUTERNAME\$userName","FullControl",`
     "ContainerInherit,ObjectInherit", "InheritOnly", "Allow";

    $aclRule = New-Object System.Security.AccessControl.FileSystemAccessRule $aclDef;
    $acl.SetAccessRule($aclRule);
    $acl | Set-Acl $path;
}

function New-PgPass($path, $userName, $password)
{
    New-Item -ItemType Directory -Force -Path $path;

    $pgPassFilePath = Join-Path $path "pgpass.conf";
    $pgPassContent = "localhost:$pgPort`:*:$userName`:$password";
    $pgPassContent | Set-Content $pgPassFilePath;
}

function Copy-Configs($configSource, $dataPath)
{
    if ( Test-Path $pgConfigSource)
    {
        Copy-Item $pgConfigSource -Filter *.conf $dataPath -Force;
    }
}

function Open-Port($name, $port)
{
    New-NetFirewallRule -DisplayName $name -Direction Inbound –Protocol TCP –LocalPort $port -Action allow -Profile Any;
}

function Set-ServiceOwner($serviceName, $user, $password)
{
    $user = ".\$user";
    $service = gwmi win32_service -computer "." -filter "name='$serviceName'";
    $service.change($null,$null,$null,$null,$null,$null,$user,$password);
    $service.StopService();
    Start-Sleep -s 2;
    $service.StartService();
}

Export-ModuleMember -Function Install-Postgres;