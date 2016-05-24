class atomia::nagios::client::atomia_database (

) {

  @@nagios_service { "${::fqdn}-domainreg-process-count":
    host_name           => $::fqdn,
    service_description => 'Total processes',
    check_command       => 'check_nrpe!check_total_procs',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-postgres-process-atomia-database":
    host_name           => $::fqdn,
    service_description => 'Postgres processes',
    check_command       => 'check_nrpe!check_postgres_proc',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
  }

}
