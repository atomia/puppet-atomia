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
#### webmail_cluster_nodes: A comma separated list of Webmail cluster nodes or empty to use all hosts with the Webmail role.
#### ssh_cluster_nodes: A comma separated list of SSH cluster nodes or empty to use all hosts with the SSH role.
#### ftp_cluster_nodes: A comma separated list of FTP cluster nodes or empty to use all hosts with the FTP role.
#### haproxy_nodes: A comma separated list of hostnames for all HAProxy load balancers in this cluster, the first one will be primary.
#### cluster_ip_auth_key: The shared secret for the Keepalived vrrp failover of the virtual IPs.
#### cluster_ip_advert_int: The time in seconds for sending multicast requests.
#### cluster_ip_check_interval: The time in seconds for checking if the service is alive.
#### cluster_ip_num_fails: The number of failed checks until failover ip goes to backup node.
#### cluster_ip_num_rise: The number of successfull checks until failover ip gets back to its master node.
#### ssl_default_bind_options: The default SSL bind options to use in the HAProxy config.
#### ssl_default_bind_ciphers: The default SSL bind cipher list to use in the HAProxy config.
#### acme_agreement: The ACME agreement to auto-approve.
#### acme_endpoint: The URL of the ACME server to use for automatic SSL certificate generation.
#### preview_domain: The hostname of the website preview zone to ignore for ACME automatic SSL generation.
#### apache_config_sync_source: A scp path to the apache shared configuration directory to sync to the loadbalancer.
#### iis_config_sync_source: A scp path to the IIS shared configuration directory to sync to the loadbalancer.

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
##### webmail_cluster_nodes(advanced): %webmail_cluster_nodes
##### ssh_cluster_nodes(advanced): %ssh_cluster_nodes
##### ftp_cluster_nodes(advanced): %ftp_cluster_nodes
##### haproxy_nodes(advanced): ^[a-z0-9,-]*$
##### cluster_ip_auth_key(advanced): %password
##### cluster_ip_advert_int(advanced): %int
##### cluster_ip_check_interval(advanced): %int
##### cluster_ip_num_fails(advanced): %int
##### cluster_ip_num_rise(advanced): %int
##### ssl_default_bind_options(advanced): .
##### ssl_default_bind_ciphers(advanced): .
##### acme_agreement(advanced): %url
##### acme_endpoint(advanced): %url
##### preview_domain(advanced): %hostname
##### apache_config_sync_source(advanced): ^.*$
##### iis_config_sync_source(advanced): ^.*$

class atomia::haproxy (
  $agent_user                      = 'haproxy',
  $agent_password                  = 'default_password',
  $enable_agent                    = '0',
  $certificate_sync_source         = 'root@fsagent:/storage/content/ssl',
  $certificate_sync_ssh_key        = '',
  $certificate_default_cert        = '',
  $virtual_ips_interface_to_manage = '',
  $virtual_ips_netmask             = '255.255.255.0',
  $apache_cluster_nodes            = '',
  $iis_cluster_nodes               = '',
  $mail_cluster_nodes              = '',
  $webmail_cluster_nodes           = '',
  $ssh_cluster_nodes               = '',
  $ftp_cluster_nodes               = '',
  $haproxy_nodes_hostnames         = '',

  $cluster_ip_auth_key             = 'default_password',
  $cluster_ip_advert_int           = 5,
  $cluster_ip_check_interval       = 5,
  $cluster_ip_num_fails            = 3,
  $cluster_ip_num_rise             = 3,

  $ssl_default_bind_options        = 'no-sslv3 no-tls-tickets',
  $ssl_default_bind_ciphers        = 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
  $acme_agreement                  = 'https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf',
  $acme_endpoint                   = 'https://acme-v01.api.letsencrypt.org/directory',
  $preview_domain                  = expand_default('preview.[[atomia_domain]]'),
  $apache_config_sync_source       = 'root@fsagent:/storage/configuration/maps',
  $iis_config_sync_source          = 'root@fsagent:/storage/configuration/iis',
  $ssl_redirects_sync_source       = 'root@fsagent:/storage/configuration'
) {

  if $haproxy_nodes_hostnames == '' {
    # TODO: Figure out way to get comma separated list of hostname for all servers with this class, in reliable order.
    $haproxy_nodes = $::hostname
  } else {
    $haproxy_nodes = $haproxy_nodes_hostnames
  }

  $apache_cluster_ip = hiera('atomia::apache_agent::cluster_ip', '')
  $iis_cluster_ip = hiera('atomia::iis::cluster_ip', '')
  $mail_cluster_ip = hiera('atomia::mailserver::cluster_ip', '')
  $ftp_cluster_ip = hiera('atomia::pureftpd::ftp_cluster_ip', '')
  $ssh_cluster_ip = hiera('atomia::sshserver::cluster_ip', '')

  class { 'apt': }

  if $::operatingsystem == 'Ubuntu' {
    package { [
      'python-software-properties',
      'software-properties-common',
      'acmetool',
    ]:
      ensure => present,
    }

    apt::ppa { 'ppa:vbernat/haproxy-1.5':
      require => Package['python-software-properties']
    }

    if $ssh_cluster_ip != '' {
      class { 'ssh::server':
        validate_sshd_file => true,
        options            => {
          'Port'   => [2022],
        },
      }
    }

    package { 'haproxy':
      ensure  => present,
      require => [ Apt::Ppa['ppa:vbernat/haproxy-1.5'] ]
    }
    

    if $virtual_ips_interface_to_manage != '' {
      sysctl::conf { 'net.ipv4.ip_nonlocal_bind':
        value => 1
      }

      package { 'keepalived':
        ensure  => present,
      }
      service { 'keepalived':
        ensure    => running,
        enable    => true,
        require   => Package['keepalived'],
      }
      service { 'heartbeat':
        enable => false,
        ensure => 'stopped',
      }

      exec { 'enable-all-interfaces':
        refreshonly => true,
        command     => '/sbin/ifup -a',
        notify      => Exec['restart-haproxy'],
        require     => Package['haproxy'],
      }

      file { '/usr/local/bin/atomia-keepalived-check.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/atomia/haproxy/atomia-keepalived-check.sh',
        require => Package['keepalived'],
      }
      file { '/etc/keepalived':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        require => Package['keepalived'],
      }
      file { '/etc/keepalived/keepalived.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('atomia/haproxy/keepalived/keepalived.conf.erb'),
        require => Package['keepalived'],
        notify  => Service['keepalived'],
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
  if !defined(Exec['restart-keepalived']) {
    exec { 'restart-keepalived':
      refreshonly => true,
      command     => '/etc/init.d/keepalived restart',
    }
  }

  $acme_conf_dirs = [ '/var/lib/acme', '/var/lib/acme/conf', '/var/lib/acme/haproxy' ]
  file { $acme_conf_dirs:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/usr/lib/stateless_acme_challenge.lua':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/var/lib/acme/conf/responses':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('atomia/haproxy/acmetool-quickstart-responses.erb'),
    require => [ Package['acmetool'], File['/var/lib/acme/conf'], File['/usr/bin/update_acmetool_challenge_script.sh'] ],
    notify  => Exec['acmetool-quickstart'],
  }

  file { '/usr/bin/update_acmetool_challenge_script.sh':
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    source => 'puppet:///modules/atomia/haproxy/update_acmetool_challenge_script.sh',
  }

  file { '/usr/bin/acmetool_sync.sh':
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    source => 'puppet:///modules/atomia/haproxy/acmetool_sync.sh',
  }

  exec { 'acmetool-quickstart':
    refreshonly => true,
    command     => '/usr/bin/acmetool quickstart --batch && /usr/bin/update_acmetool_challenge_script.sh',
    notify      => File['/etc/haproxy/haproxy.cfg'],
  }

  if $enable_agent == '1' {
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

    file { '/etc/haproxy/ssl-redirects.lst':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['haproxy']
    }

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

    file { '/etc/haproxy/sync_ssl_redirects.sh':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/atomia/haproxy/sync_ssl_redirects.sh',
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

      $sync_acmetool_cron = template('atomia/haproxy/sync_acmetool.cron')

      file { '/etc/cron.d/atomia-sync-acmetool':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $sync_acmetool_cron,
        require => [ File['/root/.ssh/id_rsa'], File['/usr/bin/acmetool_sync.sh'] ]
      }

      $sync_ssl_redirects_cron = template('atomia/haproxy/sync_ssl_redirects.cron')

      file { '/etc/cron.d/atomia-sync-ssl-redirects':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $sync_ssl_redirects_cron,
        require => [ File['/root/.ssh/id_rsa'], File['/etc/haproxy/sync_ssl_redirects.sh'] ]
      }

    }

    if $certificate_default_cert == '' {
      if($::vagrant){
        file { '/etc/haproxy/atomia_certificates/default.pem':
          ensure  => file,
          source  => 'puppet:///modules/atomiacerts/certificates/wildcard_with_key.pem',
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          require => File['/etc/haproxy/atomia_certificates']
        }
      } else {
        file { '/etc/haproxy/atomia_certificates/default.pem':
          ensure  => file,
          source  => 'puppet:///modules/atomiacerts/certificates/wildcard_with_key.pem',
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          require => File['/etc/haproxy/atomia_certificates']
        }
      }
    }

    file { '/etc/haproxy/haproxy.cfg':
      require => [
        Package['haproxy'],
        File['/etc/haproxy/atomia_certificates'],
        File['/usr/lib/stateless_acme_challenge.lua'],
        File['/var/lib/acme/haproxy'],
        File['/etc/haproxy/ssl-redirects.lst']
      ],
      notify  => Exec['restart-haproxy'],
      content => $haproxy_conf
    }
  }
}
}
