class atomia::nagios::client::pureftpd (
  ) {

  @@nagios_service { "${fqdn}-pureftpd-mountpoints":
    host_name				       => $fqdn,
    service_description	  => "NFS mounts",
    check_command			    => "check_nrpe!check_all_mountpoints",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-pureftpd-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }
  
    @@nagios_service { "${fqdn}-pureftpd-process":
    host_name   => $fqdn,
    service_description => "Pureftpd processes",
    check_command   => "check_nrpe!check_pureftpd_proc",
    use => "generic-service",
    target  => "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }


}
