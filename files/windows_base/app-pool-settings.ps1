try{
	Import-Module WebAdministration
	Get-WebApplication
	$webapps = Get-WebApplication
	foreach ($webapp in get-childitem IIS:\AppPools\)
	{
		$name = "IIS:\AppPools\" + $webapp.name
		if ( $webapp.name.StartsWith("sts") ){
			$userProfiles = (Get-ItemProperty $name processModel.loadUserProfile).Value
			if( !$userProfiles ){
				Set-ItemProperty $name processModel.loadUserProfile true
			}
		}

		$appPool = Get-Item $name
		if($appPool.startMode -eq "OnDemand") {
			$appPool.startMode = "AlwaysRunning"
			Set-Item $name $appPool
		}
		
		$idleTimeout = (Get-ItemProperty $name processModel.idleTimeout).Value.Minutes
		if($idleTimeout -ne 0) {
			Set-ItemProperty $name processModel.idleTimeout "0"
		}
		
		if ((Get-ItemProperty $name recycling.periodicRestart.time).Value.Ticks -ne 0) {
			Set-ItemProperty $name recycling.periodicRestart.time 0.00:00:00
		}
		
		if ((Get-ItemProperty $name recycling.periodicRestart.schedule.Collection).Count -ne 0) {
			Clear-ItemProperty $name recycling.periodicRestart.schedule
		}
	}

	foreach ($site in get-childitem IIS:\Sites\)
	{
		$name = "IIS:\Sites\" + $site.name
		$curSite = Get-Item $name
		if(!$curSite.applicationDefaults.preloadEnabled){
			$curSite.applicationDefaults.preloadEnabled = "true"
			Set-Item $name  $curSite
		}
	}

}catch
{
	$ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace
	$ExceptionMessage
}