$location = "c:\install"
Set-Location $location

$client = new-object System.Net.WebClient

if (!(Test-Path  (Join-Path $location "dotNetFx40_Full_setup.exe")))
{
	"Downloading .net4"
	$net4Url = "http://download.microsoft.com/download/1/B/E/1BE39E79-7E39-46A3-96FF-047F95396215/dotNetFx40_Full_setup.exe"
	$client.DownloadFile( $net4Url, (Join-Path $location "dotNetFx40_Full_setup.exe") )
	$net4Log = Join-Path $location "dotNetFx40_Full_setup.log"
	"Installing .net4"
	Start-Process dotNetFx40_Full_setup.exe ("/q /log " + $net4Log) -wait
}

new-item C:\install\installed_net40.txt -itemtype file