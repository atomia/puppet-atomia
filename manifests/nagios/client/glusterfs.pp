class atomia::nagios::client::glusterfs (
  $num_bricks = 2,
) {

  @@nagios_service { "${::fqdn}-glusterfs-process-count":
    host_name           => $::fqdn,
    service_description => 'Total processes',
    check_command       => 'check_nrpe!check_total_procs',
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-glusterfs-health-web-volume":
    host_name           => $::fqdn,
    service_description => 'GlusterFS health web_volume',
    check_command       => "check_nrpe_1arg!check_glusterfs!web_volume!${num_bricks}",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-glusterfs-health-config-volume":
    host_name           => $::fqdn,
    service_description => 'GlusterFS health config_volume',
    check_command       => "check_nrpe_1arg!check_glusterfs!config_volume!${num_bricks}",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  @@nagios_service { "${::fqdn}-glusterfs-health-mail-volume":
    host_name           => $::fqdn,
    service_description => 'GlusterFS health mail_volume',
    check_command       => "check_nrpe_1arg!check_glusterfs!mail_volume!${num_bricks}",
    use                 => 'generic-service',
    target              => "/usr/local/nagios/etc/servers/${::hostname}_service.cfg",
    owner               => 'nagios'
  }

  file_line { 'sudo_rule':
    path => '/etc/sudoers',
    line => 'nagios ALL=NOPASSWD:/usr/sbin/gluster volume status*,/usr/sbin/gluster volume heal*',
  }
}
