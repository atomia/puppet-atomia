class atomia::nagios::client::sshserver (

) {

  @@nagios_service { "${::fqdn}-sshserver-process-count":
    host_name           => $::fqdn,
    service_description => 'Total processes',
    check_command       => 'check_nrpe!check_total_procs',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-sshserver-mountpoints":
    host_name           => $::fqdn,
    service_description => 'NFS mounts',
    check_command       => 'check_nrpe!check_all_mountpoints',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
  }
}
