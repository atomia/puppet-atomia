class atomia::nagios::client::iis (
  $hostgroup,

  ) {

     @@nagios_host { "${fqdn}-host" :
        use                 => "generic-host",
        host_name           => $fqdn,
        alias			    => "IIS - $fqdn",
        address             => $ip_address,
        target              => "/usr/local/nagios/etc/servers/${hostname}_host.cfg",
        hostgroups          => $hostgroup,
        max_check_attempts  => '5'
      }    

}
