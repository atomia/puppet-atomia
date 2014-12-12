class atomia::haproxy (
  $agent_user = "haproxy",
  $agent_password = "default_password",
  $enable_agent = 1,
  $certificate_sync_source = "root@fsagent:/storage/content/ssl",
  $certificate_default_cert = "",
  $apache_cluster_ip = "127.0.0.1",
  $apache_cluster_nodes = "",
  $iis_cluster_ip = "127.0.0.2",
  $iis_cluster_nodes = "",
  $mail_cluster_ip = "127.0.0.3",
  $mail_cluster_nodes = "",
  $ftp_cluster_ip = "127.0.0.4",
  $ftp_cluster_nodes = ""
) {

  class { 'apt': }

  if $operatingsystem == "Ubuntu" {
    apt::ppa { 'ppa:vbernat/haproxy-1.5': }
 
    package { haproxy:
      ensure  => present,
      require => [Apt::Ppa['ppa:vbernat/haproxy-1.5'], Exec['apt-get-update']]
    }
 
    exec { "apt-get-update": command => "/usr/bin/apt-get update" }
  } else {
    package { haproxy: ensure => present, }
  }

  file { "/etc/default/haproxy":
    source  => "puppet:///modules/atomia/haproxy/haproxy-default",
    require => Package["haproxy"],
    notify  => Exec["restart-haproxy"],
  }
  
  if !defined(Exec['restart-haproxy']) {
    exec { "restart-haproxy":
      refreshonly => true,
      command     => "/etc/init.d/haproxy restart",
    }
  }

  if $enable_agent == 1 {
    package { atomia-pa-haproxy: ensure => present, }
 
    $haproxy_agent_conf = template("atomia/haproxy/atomia-pa-haproxy.conf.erb")
  
    file { "/etc/atomia-pa-haproxy.conf":
      owner   => root,
      group   => root,
      mode    => 440,
      content => $haproxy_agent_conf,
      require => Package["atomia-pa-haproxy"],
      notify  => Service["atomia-pa-haproxy"],
    }
  
    exec { clear-haproxy-conf:
      path     => ["/usr/bin", "/usr/sbin"],
      onlyif   => "[ x`md5sum /etc/haproxy/haproxy.cfg | cut -d ' ' -f 1` = x`grep haproxy.cfg /var/lib/dpkg/info/haproxy.md5sums | cut -d ' ' -f 1` ]",
      command  => "echo '' > /etc/haproxy/haproxy.cfg",
      provider => "shell"
    }
  
    service { "atomia-pa-haproxy":
      name      => atomia-pa-haproxy,
      enable    => true,
      ensure    => running,
      pattern   => ".*/usr/bin/atomia-pa-haproxy",
      require   => Package["atomia-pa-haproxy"],
      subscribe => File["/etc/atomia-pa-haproxy.conf"]
    }
  } else {
    $haproxy_conf = template("atomia/haproxy/haproxy.conf.erb")

    file { "/etc/haproxy/atomia_certificates":
      ensure	=> directory,
      owner	=> root,
      group	=> root,
      mode	=> 755
    }

    if $certificate_default_cert == "" {
      file { "/etc/haproxy/atomia_certificates/default.pem":
        source  => "puppet:///modules/atomiacerts/certificates/wildcard_with_key.pem",
        ensure	=> file,
        owner	=> root,
        group	=> root,
        mode	=> 755,
	require => File["/etc/haproxy/atomia_certificates"]
      }
    }

    file { "/etc/haproxy/haproxy.cfg":
      require => [ Package["haproxy"], File["/etc/haproxy/atomia_certificates"] ],
      notify  => Exec["restart-haproxy"],
      content => $haproxy_conf
    }
  }
}
