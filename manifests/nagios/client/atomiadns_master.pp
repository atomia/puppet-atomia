class atomia::nagios::client::atomiadns_master (

  ) {

  $atomiadns_password = generate("/etc/puppet/modules/atomia/files/lookup_variable.sh", "atomiadns", "agent_password")
  $atomiadns_user  = generate("/etc/puppet/modules/atomia/files/lookup_variable.sh", "atomiadns", "agent_user")

  @@nagios_service { "${fqdn}-atomiadns_master-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-atomiadns":
      host_name               => $fqdn,
      service_description     => "AtomiaDNS API",
      check_command           => "check_nrpe_1arg!check_atomiadns!atomia-nagios-test.net!$atomiadns_user!$atomiadns_password",
      use                     => "generic-service",
      target                  => "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }
}
