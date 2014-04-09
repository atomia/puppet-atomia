class atomia::iis(

){

	dism { 'NetFx3': ensure => present, all => true }
	dism { 'IIS-WebServerRole': ensure => present, all => true  }
	dism { 'IIS-WebServer': ensure => present, all => true  }
	dism { 'IIS-CommonHttpFeatures': ensure => present, all => true  }
	dism { 'IIS-Security': ensure => present, all => true  }
	dism { 'IIS-RequestFiltering': ensure => present, all => true  }
	dism { 'IIS-StaticContent': ensure => present, all => true  }
	dism { 'IIS-DefaultDocument': ensure => present, all => true  }
	dism { 'IIS-ApplicationDevelopment': ensure => present, all => true  }
	dism { 'IIS-NetFxExtensibility': ensure => present, all => true  }
	dism { 'IIS-ASPNET': ensure => present, all => true }
	dism { 'IIS-ASP': ensure => present, all => true  }
	dism { 'IIS-CGI': ensure => present, all => true  }
	dism { 'IIS-ServerSideIncludes': ensure => present, all => true  }
	dism { 'IIS-CustomLogging': ensure => present, all => true  }
	dism { 'IIS-BasicAuthentication': ensure => present, all => true  }
	dism { 'IIS-WebServerManagementTools': ensure => present, all => true  }
	dism { 'IIS-ManagementConsole': ensure => present, all => true  }

}
