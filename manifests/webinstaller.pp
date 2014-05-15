class atomia::webinstaller (
  $agent_username      = "webinstaller",
  $agent_password      = "",
  $content_mount_point = "/storage/content",
  $webinstaller_ip     = $ipaddress,
  $ssl_enabled         = false) {
  package { atomiawebinstaller-api: ensure => present }

  package { atomiawebinstaller-atomiachannel: ensure => present }

  package { atomiawebinstaller-database: ensure => present }

  package { atomiawebinstaller-masterserver: ensure => present }

  if !defined(Package['atomiawebinstaller-client']) {
    package { atomiawebinstaller-client: ensure => present }
  }

  if $ssl_enabled {
    # include apache_wildcard_ssl
  }

  class { 'atomia::apache_password_protect':
    username => $agent_username,
    password => $agent_password
  }

  service { 'apache':
    name   => apache2,
    ensure => running
  }

}

