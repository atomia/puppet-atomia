class atomia::nagios::client::fsagent (
    $account_used_for_checks = "100000"
  ) {

  $fsagent_ip = generate("/etc/puppet/modules/atomia/files/lookup_variable.sh", "fsagent", "fsagent_ip")
  $fsagent_url = "http://${fsagent_ip}:10201"
  $fsagent_username = generate("/etc/puppet/modules/atomia/files/lookup_variable.sh", "fsagent", "username")
  $fsagent_password = generate("/etc/puppet/modules/atomia/files/lookup_variable.sh", "fsagent", "password")
  @@nagios_service { "${fqdn}-fsagent-mountpoints":
    host_name				       => $fqdn,
    service_description	  => "NFS mounts",
    check_command			    => "check_nrpe!check_all_mountpoints",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-fsagent-process-count":
    host_name				       => $fqdn,
    service_description	  => "Total processes",
    check_command			    => "check_nrpe!check_total_procs",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }

  @@nagios_service { "${fqdn}-fsagent-api-check":
    host_name				       => $fqdn,
    service_description	  => "Fsagent API",
    check_command			    => "check_fsagent!${account_used_for_checks}!${fsagent_url}!${fsagent_username}!${fsagent_password}",
    use						        => "generic-service",
    target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
  }
}
