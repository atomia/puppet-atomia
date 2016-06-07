param(
	[string]$repository,
	[string]$application
)


$destination="c:\install\installer.msi"

if (!(Test-Path c:\install))
{
    New-Item -ItemType Directory -Force -Path c:\install
}

$page = [xml](new-object net.webclient).DownloadString("http://installer.atomia.com/$repository/versions.xml") | % {$_.version.entry} |? { $_.name -match "^$application$"} | sort value -Descending

$url = $page[0].metalink.files.file.resources.url.'#text'

Invoke-WebRequest $url -OutFile $destination

$msiargumentlist = "/i $destination /l*v c:\install\installlog.txt /qn /norestart"
$return = Start-Process msiexec -ArgumentList $msiArgumentList -Wait -passthru
If (@(0,3010) -contains $return.exitcode)
{
    write-host "install successful"
    exit 0
}
else {
    write-error "installation failed"
    exit 1
}
