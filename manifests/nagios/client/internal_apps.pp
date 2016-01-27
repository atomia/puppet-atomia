class atomia::nagios::client::internal_apps (
  $hostgroup,

  ) {

     @@nagios_host { "${fqdn}-host" :
        use                 => "generic-host",
        host_name           => $fqdn,
        alias			    => "Internal Apps - $fqdn",
        address             => $ip_address,
        target              => "/usr/local/nagios/etc/servers/${hostname}_host.cfg",
        hostgroups          => $hostgroup,
        max_check_attempts  => '5'
      }    

}
