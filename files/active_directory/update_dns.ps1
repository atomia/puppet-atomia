param (
    [string]$nameserver = "8.8.8.8",
    [string]$nameserver_2 = "8.8.4.4"
)
$interfaceIndex = (Get-NetIPInterface -AddressFamily IPv4 -ConnectionState Connected )


foreach ($interface in $interfaceIndex) {

    if(!(Get-DnsClientServerAddress -InterfaceIndex $interface.ifIndex | Where-Object {$_.ServerAddresses -like "*${nameserver}*"}) -And $interface.ifIndex -ne 1)
    {
        Write-Host "Update DNS of interface " $interface.ifIndex
        Set-DNSClientServerAddress -interfaceIndex $interface.ifIndex -ServerAddresses ("${nameserver}","${nameserver_2}")
    }
}
