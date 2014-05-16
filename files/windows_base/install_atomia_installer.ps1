$location = "c:\install"
Set-Location $location

$client = new-object System.Net.WebClient
"Downloading Atomia Installer"
$InstallerUrl = "http://installer.atomia.com/Atomia%20Installer-1.4.3.exe"
$client.DownloadFile( $InstallerUrl, (Join-Path $location "AtomiaInstaller.exe") )
Start-Process c:\install\AtomiaInstaller.exe ("/q /log AtomiaInstaller.txt /S")
Start-Sleep -s 10
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\AtomiaInstaller.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Atomia Installer\appupdaterw.exe"
$Shortcut.Save()

new-item C:\install\install_atomia_installer.txt -itemtype file