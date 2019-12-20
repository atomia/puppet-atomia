$location = "c:\install"
Set-Location $location

$client = new-object System.Net.WebClient
"Downloading Atomia Installer"
$InstallerUrl = "http://installer.atomia.com/AtomiaInstaller-latest.exe"
$client.DownloadFile( $InstallerUrl, (Join-Path $location "AtomiaInstaller.exe") )
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("VAGRANT\Administrator","FullControl","Allow")
$Acl = Get-Acl((Join-Path $location "AtomiaInstaller.exe"))
$Acl.SetAccessRule($Ar)
Set-Acl (Join-Path $location "AtomiaInstaller.exe") $Acl
Start-Process c:\install\AtomiaInstaller.exe ("/q /log AtomiaInstaller.txt /S")
Start-Sleep -s 10
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\AtomiaInstaller.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Atomia Installer\appupdaterw.exe"
$Shortcut.Save()

new-item C:\install\install_atomia_installer.txt -itemtype file