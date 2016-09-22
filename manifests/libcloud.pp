## Atomia Libcloud Agent

### Deploys and configures a server running Atomia Libcloud Agent.

### Variable documentation
#### service_hostname: The URL of the Atomia Libcloud Agent service.
#### service_port: The port of the Atomia Libcloud Agent service.
#### ssl_cert_file: The location to the cert file.
#### ssl_key_file: The location of the key file.
#### use_debugger: If debugger should be used.
#### processes: Number of processes to handle requests.

### Validations
##### service_hostname(advanced): %url
##### service_port(advanced): %int
##### ssl_cert_file(advanced): .*
##### ssl_key_file(advanced): .*
##### use_debugger(advanced): %boolean
##### processes(advanced): %int

class atomia::libcloud (
  $service_hostname = $::fqdn,
  $service_port     = '6789',
  $ssl_cert_file    = '',
  $ssl_key_file     = '',
  $use_debugger     = true,
  $processes        = '4'
){

  package { 'python-backports.ssl-match-hostname':
    ensure  => present
  }

  package { 'python-libcloud':
    ensure  => present ,
    require => [ Package['python-backports.ssl-match-hostname'] ]
  }

  package { 'atomialibcloudagent':
    ensure  => present ,
    require => [ Package['python-libcloud'] ]
  }

  file { '/etc/atomialibcloudagent.conf':
    path    => '/etc/atomialibcloudagent.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/libcloud/atomialibcloudagent.conf'),
    notify  => [ Service['atomialibcloudagent'] ]
  }

  service { 'atomialibcloudagent':
    ensure  => running,
    enable  => true,
    require => [ Package['atomialibcloudagent'] ],
  }

}
