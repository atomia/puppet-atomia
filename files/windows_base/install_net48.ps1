$location = "c:\install"
Set-Location $location

$client = new-object System.Net.WebClient

if (!(Test-Path  (Join-Path $location "ndp48-x86-x64-allos-enu.exe")))
{
	"Downloading .net48"
	$net4Url = "https://download.visualstudio.microsoft.com/download/pr/2d6bb6b2-226a-4baa-bdec-798822606ff1/8494001c276a4b96804cde7829c04d7f/ndp48-x86-x64-allos-enu.exe"
	$client.DownloadFile( $net4Url, (Join-Path $location "ndp48-x86-x64-allos-enu.exe") )
	$net4Log = Join-Path $location "ndp48-x86-x64-allos-enu.log"
	"Installing .net4"
	Start-Process ndp48-x86-x64-allos-enu.exe ("/q /log " + $net4Log) -wait
}

new-item C:\install\ndp48-x86-x64-allos-enu.txt -itemtype file