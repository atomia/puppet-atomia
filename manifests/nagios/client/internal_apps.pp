class atomia::nagios::client::internal_apps (
  $hostgroup,

) {

  @@nagios_host { "${::fqdn}-host" :
    use                => 'generic-host',
    host_name          => $::fqdn,
    alias              => "Internal Apps - ${::fqdn}",
    address            => $::ip_address,
    target             => "/usr/local/nagios/etc/servers/${::hostname}_host.cfg",
    hostgroups         => $hostgroup,
    max_check_attempts => '5'
  }

  @@nagios_service { "${::fqdn}-iis-service-status":
    host_name           => $::fqdn,
    service_description => 'IIS service status',
    check_command       => 'check_nt_service!W3SVC',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-as-cleanup-status":
    host_name           => $::fqdn,
    service_description => 'Automationserver cleanup service status',
    check_command       => "check_nt_service!'Atomia Automation Server Clean Up Service'",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-as-updater-status":
    host_name           => $::fqdn,
    service_description => 'Automationserver periodic updater service status',
    check_command       => "check_nt_service!'Atomia Automation Server Periodic Updater'",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }
  @@nagios_service { "${::fqdn}-as-engine-status":
    host_name           => $::fqdn,
    service_description => 'Automationserver provisioning engine service status',
    check_command       => "check_nt_service!'Atomia Automation Server Provisioning Engine'",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-mail-dispatcher-status":
    host_name           => $::fqdn,
    service_description => 'Atomia mail dispatcher service status',
    check_command       => "check_nt_service!'Atomia Mail Dispatcher'",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-ticker-service-status":
    host_name           => $::fqdn,
    service_description => 'Atomia ticker service status',
    check_command       => "check_nt_service!'Atomia Ticker Service'",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

}
