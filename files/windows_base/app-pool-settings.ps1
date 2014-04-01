try{
	Import-Module WebAdministration
	Get-WebApplication
	$webapps = Get-WebApplication
	foreach ($webapp in get-childitem IIS:\AppPools\)
	{	
		if ( $webapp.name.StartsWith("sts") ){
			
			$name = "IIS:\AppPools\" + $webapp.name
			$userProfiles = (Get-ItemProperty $name processModel.loadUserProfile).Value
			if( !$userProfiles ){
				Set-ItemProperty $name processModel.loadUserProfile true			
			}
		}
	}	

}catch
{
	$ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace
	$ExceptionMessage
}