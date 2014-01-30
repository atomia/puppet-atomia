class atomia::atomiadns (
  # Name server group
  $ns_group          = "default",
  $ssl_enabled       = 0,
  $agent_user        = "atomiadns",
  $agent_password    = "",
  $atomia_dns_url    = "http://localhost/atomiadns",
  $nameserver1       = "",
  $nameservers       = "",
  $registry          = "",
  $zones_to_add      = "",
  $dns_ns_group,
  $atomia_dns_config = 0) {
  package { atomiadns-masterserver: ensure => present }

  if !defined(Package['atomiadns-client']) {
    package { atomiadns-client: ensure => latest }
  }

  if $ssl_enabled == '1' {
    include apache_wildcard_ssl
  }

  if !defined(Class['atomia::apache_password_protect']) {
    class { 'atomia::apache_password_protect':
      username => $agent_user,
      password => $agent_password
    }
  }

  # TODO: Rewrite this section
  # if $dns_ns_group {
  # if is_array($atomia_dns_config)
  #{
  # 	each($atomia_dns_config) | $val|
  # 	{
  # 		exec { "/usr/bin/sudo -u postgres psql zonedata -c \"INSERT INTO nameserver_group (name) VALUES ('${val[ns_group]}')\"":
  # 			require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"], Package["sudo"] ],
  # 			unless => "/usr/bin/sudo -u postgres psql zonedata -tA -c \"SELECT name FROM nameserver_group WHERE name =
  #    '${val[ns_group]}'\" | grep '^${val[ns_group]}\$'",
  # 		}
  # 	}
  #}
  # else
  #{
  exec { add_nameserver_group:
    require => [Package["atomiadns-masterserver"], Package["atomiadns-client"]],
    unless  => "/usr/bin/sudo -u postgres psql zonedata -tA -c \"SELECT name FROM nameserver_group WHERE name = '$ns_group'\" | grep '^$ns_group\$'",
    command => "/usr/bin/sudo -u postgres psql zonedata -c \"INSERT INTO nameserver_group (name) VALUES ('$ns_group')\"",
  }
}

#}

if $ssl_enabled {
  file { "/etc/atomiadns-mastercert.pem":
    owner  => root,
    group  => root,
    mode   => 440,
    source => "puppet:///modules/atomiadns/atomiadns_cert"
  }

  $atomiadns_conf = generate("/etc/puppet/modules/atomiadns/files/generate_conf.sh", $agent_user, $agent_password, $hostname, 
  $dns_url, "ssl")

} else {
  $atomiadns_conf = generate("/etc/puppet/modules/atomiadns/files/generate_conf.sh", $agent_user, $agent_password, $hostname, 
  $dns_url, "nossl")
}

file { "/etc/atomiadns.conf.master":
  owner   => root,
  group   => root,
  mode    => 444,
  content => $atomiadns_conf,
  require => Package["atomiadns-masterserver"],
}

file { "/usr/bin/atomiadns_config_sync":
  owner   => root,
  group   => root,
  mode    => 500,
  source  => "puppet:///modules/atomiadns/atomiadns_config_sync",
  require => [Package["atomiadns-masterserver"]],
}

exec { "atomiadns_config_sync":
  require => [File["/usr/bin/atomiadns_config_sync"], File["/etc/atomiadns.conf.master"]],
  command => "/usr/bin/atomiadns_config_sync $atomia_dns_ns_group",
  unless  => "/bin/grep  soap_uri /etc/atomiadns.conf",
}

if $zones_to_add {
  file { "/usr/share/doc/atomiadns-masterserver/zones_to_add.txt":
    owner   => root,
    group   => root,
    mode    => 500,
    content => $zones_to_add,
    require => [Package["atomiadns-masterserver"], Package["atomiadns-client"]],
    notify  => Exec['remove_lock_file'],
  }

  exec { "remove_lock_file":
    command     => "/bin/rm -f /usr/share/doc/atomiadns-masterserver/sync_zones_done*.txt",
    refreshonly => true,
  }

  file { "/usr/share/doc/atomiadns-masterserver/add_zones.sh":
    owner   => root,
    group   => root,
    mode    => 500,
    source  => "puppet:///modules/atomia/atomiadns/add_zones.sh",
    require => [Package["atomiadns-masterserver"], Package["atomiadns-client"]],
  }

  # TODO: rewrite this section
  # if is_array($atomia_dns_config)
  #{
  # each($atomia_dns_config) |$c|
  #{

  # file { "/usr/share/doc/atomiadns-masterserver/zones_to_add_${c[ns_group]}.txt":
  # 	owner   => root,
  # 	group   => root,
  # 	mode    => 500,
  # 	content	=> $c[zones],
  # 	require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
  # 	notify  => Exec['remove_lock_file'],
  #}
  # exec { "/bin/sh /usr/share/doc/atomiadns-masterserver/add_zones.sh ${c[ns_group]} ${c[nameserver1]}
  # ${c[nameservers]} ${c[registry]}" :
  # 		require => [ File["/usr/share/doc/atomiadns-masterserver/zones_to_add_${c[ns_group]}.txt"]],
  # 		unless => "/usr/bin/test -f /usr/share/doc/atomiadns-masterserver/sync_zones_done_${c[ns_group]}.txt",
  # 	}
  #}
  #}
  # else
  #{

  file { "/usr/share/doc/atomiadns-masterserver/zones_to_add.txt":
    owner   => root,
    group   => root,
    mode    => 500,
    content => $zones_to_add,
    require => [Package["atomiadns-masterserver"], Package["atomiadns-client"]],
    notify  => Exec['remove_lock_file'],
  }

  exec { "atomiadns_add_zones":
    require => [File["/usr/share/doc/atomiadns-masterserver/zones_to_add.txt"]],
    command => "/bin/sh /usr/share/doc/atomiadns-masterserver/add_zones.sh $ns_group $nameserver1 $nameservers $registry",
    unless  => "/usr/bin/test -f /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt",
  }
  #}
  #}
}

