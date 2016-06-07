## Atomia HAProxy load balancer

### Deploys and configures a loadbalancer or a cluster of loadbalancers running HAProxy.

### Variable documentation
#### agent_user: The username to require when accessing the HAProxy agent.
#### agent_password: The password to require when accessing the HAProxy agent.
#### enable_agent: If true then install the HAProxy agent instead of the default mode where the config is controlled by puppet.
#### certificate_sync_source: A scp path to the customer SSL directory to sync to the loadbalancer.
#### certificate_sync_ssh_key: The SSH key to use when syncing certificates (needs to have access, normally made available by the fsagent role)
#### certificate_default_cert: The default certificate and key for SSL (should normally be the wildcard cert used for the environment) in PEM format.
#### virtual_ips_interface_to_manage: The interface bound to the network containing the virtual cluster IPs or empty to not manage the IPs.
#### virtual_ips_netmask: The netmask for the network containing the virtual cluster IPs.
#### apache_cluster_nodes: A comma separated list of Apache cluster nodes or empty to use all hosts with the Apache role.
#### iis_cluster_nodes: A comma separated list of IIS cluster nodes or empty to use all hosts with the IIS role.
#### mail_cluster_nodes: A comma separated list of Mail cluster nodes or empty to use all hosts with the Mail role.
#### ftp_cluster_nodes: A comma separated list of FTP cluster nodes or empty to use all hosts with the FTP role.
#### haproxy_nodes: A comma separated list of hostnames for all HAProxy load balancers in this cluster, the first one will be primary.
#### cluster_ip_auth_key: The shared secret for the Heartbeat failover of the virtual IPs.
#### cluster_ip_warntime: The value to use for the warntime Heartbeat configuration option.
#### cluster_ip_deadtime: The value to use for the deadtime Heartbeat configuration option.
#### cluster_ip_initdead: The value to use for the initdead Heartbeat configuration option.
#### cluster_ip_keepalive: The value to use for the keepalive Heartbeat configuration option.

### Validations
##### agent_user(advanced): %username
##### agent_password(advanced): %password
##### enable_agent(advanced): %int_boolean
##### certificate_sync_source(advanced): ^.*$
##### certificate_sync_ssh_key(advanced): ^ssh-rsa .*$
##### certificate_default_cert(advanced): ^-----BEGIN.*-----$
##### virtual_ips_interface_to_manage(advanced): ^[a-z]+[0-9]+$
##### virtual_ips_netmask(advanced): %ip
##### apache_cluster_nodes(advanced): %apache_cluster_nodes
##### iis_cluster_nodes(advanced): %iis_cluster_nodes
##### mail_cluster_nodes(advanced): %mail_cluster_nodes
##### ftp_cluster_nodes(advanced): %ftp_cluster_nodes
##### haproxy_nodes(advanced): ^[a-z0-9,-]*$
##### cluster_ip_auth_key(advanced): %password
##### cluster_ip_warntime(advanced): %int
##### cluster_ip_deadtime(advanced): %int
##### cluster_ip_initdead(advanced): %int
##### cluster_ip_keepalive(advanced): %int

class atomia::haproxy (
  $agent_user                      = 'haproxy',
  $agent_password                  = 'default_password',
  $enable_agent                    = 0,
  $certificate_sync_source         = 'root@fsagent:/storage/content/ssl',
  $certificate_sync_ssh_key        = '',
  $certificate_default_cert        = '',
  $virtual_ips_interface_to_manage = '',
  $virtual_ips_netmask             = '255.255.255.0',
  $apache_cluster_nodes            = '',
  $iis_cluster_nodes               = '',
  $mail_cluster_nodes              = '',
  $ftp_cluster_nodes               = '',
  $haproxy_nodes_hostnames         = '',
  $cluster_ip_auth_key             = 'default_password',
  $cluster_ip_warntime             = 5,
  $cluster_ip_deadtime             = 15,
  $cluster_ip_initdead             = 60,
  $cluster_ip_keepalive            = 2,
) {

  if $haproxy_nodes_hostnames != '' {
    # TODO: Figure out way to get comma separated list of hostname for all servers with this class, in reliable order.
    $haproxy_nodes = $::hostname
  } else {
    $haproxy_nodes = $haproxy_nodes_hostnames
  }

  $apache_cluster_ip = hiera('atomia::apache_agent::cluster_ip', '')
  $iis_cluster_ip = hiera('atomia::iis::cluster_ip', '')
  $mail_cluster_ip = hiera('atomia::mailserver::cluster_ip', '')
  $ftp_cluster_ip = hiera('atomia::pureftpd::ftp_cluster_ip', '')

  class { 'apt': }

  if $::operatingsystem == 'Ubuntu' {
    package { [
      'python-software-properties',
      'software-properties-common',
    ]:
      ensure => present,
    }

    apt::ppa { 'ppa:vbernat/haproxy-1.5':
      require => Package['python-software-properties']
    }

    package { 'haproxy':
      ensure  => present,
      require => [ Apt::Ppa['ppa:vbernat/haproxy-1.5'] ]
    }

    if $virtual_ips_interface_to_manage != '' {
      sysctl::conf { 'net.ipv4.ip_nonlocal_bind':
        value => 1
      }

      exec { 'enable-all-interfaces':
        refreshonly => true,
        command     => '/sbin/ifup -a',
        notify      => Exec['restart-haproxy'],
        require     => Package['haproxy'],
      }

      haproxy::ipalias { 'apache_vip':
        interface => $virtual_ips_interface_to_manage,
        ip        => $apache_cluster_ip,
        netmask   => $virtual_ips_netmask,
        alias_num => 1
      }

      haproxy::ipalias { 'iis_vip':
        interface => $virtual_ips_interface_to_manage,
        ip        => $iis_cluster_ip,
        netmask   => $virtual_ips_netmask,
        alias_num => 2
      }

      haproxy::ipalias { 'mail_vip':
        interface => $virtual_ips_interface_to_manage,
        ip        => $mail_cluster_ip,
        netmask   => $virtual_ips_netmask,
        alias_num => 3
      }

      haproxy::ipalias { 'ftp_vip':
        interface => $virtual_ips_interface_to_manage,
        ip        => $ftp_cluster_ip,
        netmask   => $virtual_ips_netmask,
        alias_num => 4
      }

      file { '/etc/ha.d/ha.cf':
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('atomia/haproxy/ha.d/ha.cf.erb'),
        require => Package['heartbeat'],
        notify  => Service['heartbeat'],
      }

      file { '/etc/ha.d/authkeys':
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => template('atomia/haproxy/ha.d/authkeys.erb'),
        require => Package['heartbeat'],
        notify  => Service['heartbeat'],
      }

      file { '/etc/ha.d/haresources':
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('atomia/haproxy/ha.d/haresources.erb'),
        require => Package['heartbeat'],
        notify  => Service['heartbeat'],
      }

      package { 'heartbeat': ensure => present }

      service { 'heartbeat':
        ensure  => running,
        enable  => true,
        require => Package['heartbeat'],
      }
    }
  } else {
    package { 'haproxy': ensure => present }
  }

  file { '/etc/default/haproxy':
    source  => 'puppet:///modules/atomia/haproxy/haproxy-default',
    require => Package['haproxy'],
    notify  => Exec['restart-haproxy'],
  }

  if !defined(Exec['restart-haproxy']) {
    exec { 'restart-haproxy':
      refreshonly => true,
      command     => '/etc/init.d/haproxy restart',
    }
  }

  if $enable_agent == 1 {
    package { 'atomia-pa-haproxy': ensure => present, }

    $haproxy_agent_conf = template('atomia/haproxy/atomia-pa-haproxy.conf.erb')

    file { '/etc/atomia-pa-haproxy.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      content => $haproxy_agent_conf,
      require => Package['atomia-pa-haproxy'],
      notify  => Service['atomia-pa-haproxy'],
    }

    exec { 'clear-haproxy-conf':
      path     => ['/usr/bin', '/usr/sbin'],
      onlyif   => "[ x`md5sum /etc/haproxy/haproxy.cfg | cut -d ' ' -f 1` = x`grep haproxy.cfg /var/lib/dpkg/info/haproxy.md5sums | cut -d ' ' -f 1` ]",
      command  => "echo '' > /etc/haproxy/haproxy.cfg",
      provider => 'shell'
    }

    service { 'atomia-pa-haproxy':
      ensure    => running,
      enable    => true,
      pattern   => '.*/usr/bin/atomia-pa-haproxy',
      require   => Package['atomia-pa-haproxy'],
      subscribe => File['/etc/atomia-pa-haproxy.conf']
    }
  } else {
    $haproxy_conf = template('atomia/haproxy/haproxy.conf.erb')

    file { '/etc/haproxy/atomia_certificates':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Package['haproxy']
    }

    package { 'rsync':
      ensure => present
    }

    file { '/etc/haproxy/sync_certificates.sh':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/atomia/haproxy/sync_certificates.sh',
      require => [ Package['haproxy'], Package['rsync'] ]
    }


    if $certificate_sync_ssh_key != '' {
      file { '/root/.ssh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
      }

      file { '/root/.ssh/id_rsa':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $certificate_sync_ssh_key
      }

      $sync_certs_cron = template('atomia/haproxy/sync_certificates.cron')

      file { '/etc/cron.d/atomia-sync-certificates':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $sync_certs_cron,
        require => File['/root/.ssh/id_rsa']

      }
    }

    if $certificate_default_cert == '' {
      file { '/etc/haproxy/atomia_certificates/default.pem':
        ensure  => file,
        source  => 'puppet:///modules/atomiacerts/certificates/wildcard_with_key.pem',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/haproxy/atomia_certificates']
      }
    }

    file { '/etc/haproxy/haproxy.cfg':
      require => [ Package['haproxy'], File['/etc/haproxy/atomia_certificates'] ],
      notify  => Exec['restart-haproxy'],
      content => $haproxy_conf
    }
  }
}

define haproxy::ipalias(
  $alias_num,
  $interface = '',
  $ip        = '',
  $netmask   = '',
) {

  if $ip != '' {
    augeas { "haproxy_ipalias_${ip}":
      context => '/files/etc/network/interfaces',
      changes => [
        "set auto[child::1 = '${interface}:${alias_num}']/1 ${interface}:${alias_num}",
        "set iface[. = '${interface}:${alias_num}'] ${interface}:${alias_num}",
        "set iface[. = '${interface}:${alias_num}']/family inet",
        "set iface[. = '${interface}:${alias_num}']/method static",
        "set iface[. = '${interface}:${alias_num}']/address ${ip}",
        "set iface[. = '${interface}:${alias_num}']/netmask ${netmask}",
      ],
      notify  => Exec['enable-all-interfaces'],
      before  => [ Package['heartbeat'], Service['heartbeat'] ]
    }
  }
}
