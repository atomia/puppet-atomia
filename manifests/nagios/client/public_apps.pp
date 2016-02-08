class atomia::nagios::client::public_apps (
  $hostgroup,

  ) {

     @@nagios_host { "${fqdn}-host" :
        use                 => "generic-host",
        host_name           => $fqdn,
        alias			    => "Public Apps - $fqdn",
        address             => $ip_address,
        target              => "/usr/local/nagios/etc/servers/${hostname}_host.cfg",
        hostgroups          => $hostgroup,
        max_check_attempts  => '5'
      }  
      
  @@nagios_service { "${fqdn}-iis-service-status":
      host_name               => $fqdn,
      service_description     => "IIS service status",
      check_command           => "check_nt_service!W3SVC",
      use                     => "generic-service",
      target              	=> "/usr/local/nagios/etc/servers/${hostname}_service.cfg",
      owner                 => "nagios"
  }            

}
