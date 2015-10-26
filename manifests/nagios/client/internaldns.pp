class atomia::nagios::client::internaldns (

  ) {

  @@nagios_service { "${fqdn}-internaldns-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
    owner                 => "nagios"
  }



}
