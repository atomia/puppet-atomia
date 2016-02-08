class atomia::nagios::client::daggre (

  ) {

  @@nagios_service { "${fqdn}-daggre-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
    owner                 => "nagios"
  }


  @@nagios_service { "${fqdn}-daggre-process":
    host_name   => $fqdn,
    service_description => "Daggre processes",
    check_command   => "check_nrpe!check_daggre_proc",
    use => "generic-service",
    target  => "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }


  @@nagios_service { "${fqdn}-daggre-check-ftp":
    host_name   => $fqdn,
    service_description => "Daggre FTP",
    check_command   => "check_nrpe!check_daggre_ftp",
    use => "generic-service",
    target  => "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-daggre-check-weblog":
    host_name   => $fqdn,
    service_description => "Daggre Weblog",
    check_command   => "check_nrpe!check_daggre_weblog",
    use => "generic-service",
    target  => "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

}
