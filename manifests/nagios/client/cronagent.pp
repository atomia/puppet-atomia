class atomia::nagios::client::cronagent (

) {

  @@nagios_service { "${::fqdn}-cronagent-process-count":
    host_name           => $::fqdn,
    service_description => 'Total processes',
    check_command       => 'check_nrpe!check_total_procs',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }


  @@nagios_service { "${::fqdn}-cronagent-process":
    host_name           => $::fqdn,
    service_description => 'Cronagent processes',
    check_command       => 'check_nrpe!check_cronagent_proc',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
  }

}
