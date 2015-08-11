class atomia::nagios::client::awstats (
    $account_used_for_checks = "100000"
  ) {

  @@nagios_service { "${fqdn}-awstats-mountpoints":
    host_name				       => $fqdn,
    service_description	  => "NFS mounts",
    check_command			    => "check_nrpe!check_all_mountpoints",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-awstats-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }


}
