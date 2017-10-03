class atomia::nagios::client::atomiadns_master (

) {

  $atomiadns_password = hiera('atomia::atomiadns::agent_password','')
  $atomiadns_user     = hiera('atomia::atomiadns::agent_user','')
  $atomiadns_url      = hiera('atomia::atomiadns::atomia_dns_url','')

  @@nagios_service { "${::fqdn}-atomiadns_master-process-count":
    host_name           => $::fqdn,
    service_description => 'Total processes',
    check_command       => 'check_nrpe!check_total_procs',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-atomiadns":
    host_name           => $::fqdn,
    service_description => 'AtomiaDNS API',
    check_command       => "check_nrpe_1arg!check_atomiadns!atomia-nagios-test.net!${atomiadns_user}!${atomiadns_password}",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }
}
