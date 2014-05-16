Function ImportPfxCertificate($CertFileToImport, $CertStoreName)
{ 
	# Define The Password That Protects The Private Key
	# (ALSO see: http://jorgequestforknowledge.wordpress.com/2011/12/15/passwords-containing-special-characters-in-powershell/)
	$PrivateKeyPassword = ''

	$ImportFlags = "MachineKeySet, Exportable, PersistKeySet"
	$CertToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $CertFileToImport,$PrivateKeyPassword,$ImportFlags

	# Define The Scope And Certificate Store Within That Scope To Import The Certificate Into
	# Available Cert Store Scopes are "LocalMachine" or "CurrentUser"
	$CertStoreScope = "LocalMachine"
	# For Available Cert Store Names See Figure 5 (Depends On Cert Store Scope)
	#$CertStoreName = "My"
	$CertStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $CertStoreName, $CertStoreScope

	# Import The Targeted Certificate Into The Specified Cert Store Name Of The Specified Cert Store Scope
	$CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
	$CertStore.Add($CertToImport)
	$CertStore.Close()
}

ImportPfxCertificate "C:\install\certificates\root.pfx" "Root"
ImportPfxCertificate "C:\install\certificates\actiontrail.pfx" "My"
ImportPfxCertificate "C:\install\certificates\wildcard.pfx" "My"
ImportPfxCertificate "C:\install\certificates\accountapi.pfx" "My"
ImportPfxCertificate "C:\install\certificates\automationserver.pfx" "My"
ImportPfxCertificate "C:\install\certificates\billingencrypt.pfx" "My"
ImportPfxCertificate "C:\install\certificates\billingapi.pfx" "My"
ImportPfxCertificate "C:\install\certificates\billing.pfx" "My"
ImportPfxCertificate "C:\install\certificates\guicert.pfx" "My"
ImportPfxCertificate "C:\install\certificates\guicert.pfx" "TrustedPeople"
ImportPfxCertificate "C:\install\certificates\stssigning.pfx" "My"
ImportPfxCertificate "C:\install\certificates\stssigning.pfx" "TrustedPeople"
ImportPfxCertificate "C:\install\certificates\automationencrypt.pfx" "My"
ImportPfxCertificate "C:\install\certificates\hcp.pfx" "My"
ImportPfxCertificate "C:\install\certificates\orderapi.pfx" "My"
ImportPfxCertificate "C:\install\certificates\sts.pfx" "My"
ImportPfxCertificate "C:\install\certificates\userapi.pfx" "My"
ImportPfxCertificate "C:\install\certificates\admin.pfx" "My"
ImportPfxCertificate "C:\install\certificates\login.pfx" "My"

new-item C:\install\install_certificates.txt -itemtype file