class atomia::adjoin_config (

){
  $factfile = '/etc/facter/facts.d/ad_servers.txt'

  file { '/etc/facter':
    ensure => directory,
  }
  file { '/etc/facter/facts.d':
    ensure  => directory,
    require => File['/etc/facter']
  }
  concat { $factfile:
    ensure  => present,
    require => File['/etc/facter/facts.d']
  }
  concat::fragment {'active_directory_content':
    target  => $factfile,
    content => 'ad_servers=',
    tag     => 'ad_servers',
    order   => 3
  } ->
  Concat::Fragment <<| tag == 'ad_servers' |>>

  service { 'nscd':
    ensure => stopped,
    enable => false,
  }
  file { '/etc/pam.d/common-account':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/atomia/adjoin/common-account',
  }

  file { '/etc/nsswitch.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/atomia/adjoin/nsswitch.conf',
  }

  file { '/etc/ldap.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('atomia/adjoin/ldap.conf.erb'),
  }

}

file { '/etc/pam.d/common-auth':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/atomia/adjoin/common-auth',
}

file { '/etc/pam.d/common-session':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/atomia/adjoin/common-session',
}

define atomia::adjoin_config::register ($content='', $order='10') {
  $factfile = '/etc/facter/facts.d/ad_servers.txt'

  @@concat::fragment {"active_directory_${content}":
    target  => $factfile,
    content => "${content} ",
    tag     => 'ad_servers',
    order   => 3
  }
}
