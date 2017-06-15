$location = "c:\install"
Set-Location $location

$client = new-object System.Net.WebClient

if (!(Test-Path  (Join-Path $location "net461.exe")))
{
	"Downloading .net461"
	$net4Url = "https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe"
	$client.DownloadFile( $net4Url, (Join-Path $location "net461.exe") )
	$net4Log = Join-Path $location "net461.log"
	"Installing .net4"
	Start-Process net461.exe ("/q /log " + $net4Log) -wait
}

new-item C:\install\installed_net461.txt -itemtype file