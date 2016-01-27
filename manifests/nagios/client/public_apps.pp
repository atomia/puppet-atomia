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

}
