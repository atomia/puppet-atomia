class atomia::nagios::client::active_directory (
  $hostgroup,

) {

  @@nagios_host { "${::fqdn}-host" :
    use                => 'generic-host',
    host_name          => $::fqdn,
    alias              => "Active Directory - ${::fqdn}",
    address            => $::ip_address,
    target             => "/usr/local/nagios/etc/servers/${::hostname}_host.cfg",
    hostgroups         => $hostgroup,
    max_check_attempts => '5'
  }

}
