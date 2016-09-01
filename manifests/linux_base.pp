class atomia::linux_base {

  package { 'sudo': ensure => present }

  include '::ntp'

  $internal_dns = hiera('atomia::internaldns::ip_address', '')

  if !defined(File['/etc/facter']){
    file { '/etc/facter':
      ensure  => directory,
    }
  }

  if !defined(File['/etc/facter/facts.d']){
    file { '/etc/facter/facts.d':
      ensure  => directory,
      require => File['/etc/facter'],
    }
  }

  if $internal_dns != '' {
    if ($::atomia_role_1 != 'glusterfs') and ($::atomia_role_1 != 'glusterfs_replica') {
      class { 'resolv_conf':
        nameservers => [$internal_dns],
      }
    }
    else {
      $nameserver1 = hiera('atomia::active_directory::master_ip','')
      $nameserver2 = hiera('atomia::active_directory_replica::replica_ip','')
      if($nameserver2 == ''){
        class { 'resolv_conf':
          nameservers => [$nameserver1],
        }
      }
      else {
        class { 'resolv_conf':
          nameservers => [$nameserver1, $nameserver2],
        }
      }
    }

    # Add Puppetmaster to local hosts file
    host { 'puppetmaster-host':
      ensure => present,
      name   => hiera('atomia::config::puppet_hostname'),
      ip     => hiera('atomia::config::puppet_ip'),
    }

    Host <<| |>>
  }
}

define atomia::hostname::register ($content='', $order='10') {
  $factfile = '/etc/hosts'

  @@concat::fragment {"hostnames_${content}":
    target  => $factfile,
    content => "${content} ",
    tag     => 'hosts_file',
    order   => 3
  }

}

define limits::conf (
  $domain = 'root',
  $type = 'soft',
  $item = 'nofile',
  $value = '10000'
) {

  $key = "${domain}/${type}/${item}"
  $context = '/files/etc/security/limits.conf'
  $path_list  = "domain[.=\"${domain}\"][./type=\"${type}\" and ./item=\"${item}\"]"
  $path_exact = "domain[.=\"${domain}\"][./type=\"${type}\" and ./item=\"${item}\" and ./value=\"${value}\"]"

  augeas { "limits_conf/${key}":
    context => $context,
    onlyif  => "match ${path_exact} size != 1",
    changes => [
      # remove all matching to the $domain, $type, $item, for any $value
      "rm ${path_list}",
      # insert new node at the end of tree
      "set domain[last()+1] ${domain}",
      # assign values to the new node
      "set domain[last()]/type ${type}",
      "set domain[last()]/item ${item}",
      "set domain[last()]/value ${value}",
    ],
  }
}

define sysctl::conf ($value) {
  exec { 'sysctl':
    command => '/sbin/sysctl -p',
    refreshonly => true,
  }

  augeas { "sysctl_conf/${title}":
    context => '/files/etc/sysctl.conf',
    onlyif  => "get ${title} != '${value}'",
    changes => "set ${title} '${value}'",
    notify  => Exec['sysctl'],
  }
}
