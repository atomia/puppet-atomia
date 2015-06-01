class atomia::nagios::client::nameserver (

  ) {

  @@nagios_service { "${fqdn}-nameserver-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-nameserver-process-powerdnssync":
    host_name				       => $fqdn,
    service_description	  => "Powerdnssync",
    check_command			    => "check_nrpe!check_powerdnssync_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-nameserver-dig":
    host_name				       => $fqdn,
    service_description	  => "Dig",
    check_command			    => "check_dig!${hostname}!atomia-nagios-test.net!ANY",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

}
