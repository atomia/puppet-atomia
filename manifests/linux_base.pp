class atomia::linux_base {

    package { 'sudo': ensure => present }

    include '::ntp'

    $internal_dns = hiera('atomia::internaldns::ip_address', '')

    $factfile = '/etc/facter/facts.d/ad_server.txt'
   
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
    
    if($atomia_role_1 != 'nagios_server' and $atomia_role_1 != 'atomia_database'){    
        concat {  $factfile:
        ensure => present,
        force => true,
        require => File['/etc/facter/facts.d'],
        }    
        
        Concat::Fragment <<| tag == 'dc_ip_linux' |>>
    }
    if $internal_dns != '' {
      if ($atomia_role_1 != "glusterfs") and ($atomia_role_1 != "glusterfs_replica") {
        class { 'resolv_conf':
          nameservers => ["${internal_dns}"],
        }
      }
      else {
        if($ad_server){
          class { 'resolv_conf':
            nameservers => ["${ad_server}"],
          }
        }
      }
	  
	  # Add Puppetmaster to local hosts file
	  host { 'puppetmaster-host':
	  	name 	=> hiera('atomia::config::puppet_hostname'),
      ensure 	=> present,
      ip 		=> hiera('atomia::config::puppet_ip'),
	  }

      Host <<| |>>
    }
}

define atomia::hostname::register ($content="", $order='10') {
  $factfile = '/etc/hosts'

  @@concat::fragment {"hostnames_${content}":
      target => $factfile,
      content => "${content} ",
      tag => 'hosts_file',
      order => 3
    }

}

define limits::conf (
	$domain = "root",
	$type = "soft",
	$item = "nofile",
	$value = "10000"
	) {

	$key = "$domain/$type/$item"
	$context = "/files/etc/security/limits.conf"
	$path_list	= "domain[.=\"$domain\"][./type=\"$type\" and ./item=\"$item\"]"
	$path_exact = "domain[.=\"$domain\"][./type=\"$type\" and ./item=\"$item\" and ./value=\"$value\"]"

	augeas { "limits_conf/$key":
		 context => "$context",
		 onlyif  => "match $path_exact size != 1",
		 changes => [
			 # remove all matching to the $domain, $type, $item, for any $value
			 "rm $path_list",
			 # insert new node at the end of tree
			 "set domain[last()+1] $domain",
			 # assign values to the new node
			 "set domain[last()]/type $type",
			 "set domain[last()]/item $item",
			 "set domain[last()]/value $value",
		 ],
	 }
}

define sysctl::conf ($value) {
	exec { "/sbin/sysctl -p":
		alias => "sysctl",
		refreshonly => true,
	}

	augeas { "sysctl_conf/$title":
		context => "/files/etc/sysctl.conf",
		onlyif  => "get $title != '$value'",
		changes => "set $title '$value'",
		notify  => Exec["sysctl"],
	}
} 
