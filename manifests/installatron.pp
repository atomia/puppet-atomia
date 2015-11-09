#
# == Class: atomia::installatron
#
# Manifest to install/configure Installatron
#
# [license_key]
# Your installatron license key
# (required) 
#
# [content_share_nfs_location]
# Location of the content nfs share
# (required)
#
# === Examples
#
# class {'atomia::installatron':
#   license_key                     => 'YOUR_LICENSE_KEY ',
#	content_share_nfs_location		=> '127.0.0.1:/export/content',
#}

class atomia::installatron (
  	$license_key,
  	$content_share_nfs_location
  ) {
    
  package { [
  	'apache2',
  	'curl',
  	'perl',
  	'php5',
  	'php5-gd',
  	'libapache2-mod-php5',
  	'php5-sqlite'
  ]:
  	ensure => installed,
  }

  atomia::nfsmount { 'mount_content':
    use_nfs3 => $use_nfs3,
    mount_point => '/storage/content',
    nfs_location => $content_share_nfs_location
  }
    

  service { 'apache2': 
  	ensure		=> running,
  	require 	=> Package['apache2'],
  }

  exec { 'fetch-installatron-package':
  	command		=> '/usr/bin/wget http://data.installatron.com/installatron-server_latest_all.deb -O /root/installatron-server_latest_all.deb',
  	unless		=> '/bin/ls -l /root/installatron-server_latest_all.deb  | /bin/grep -c installatron',
  	require 	=> Package['curl'],
  }

  exec { 'install-installatron-package': 
  	command		=> '/etc/profile.d/installatron-key.sh && /usr/bin/dpkg -i /root/installatron-server_latest_all.deb',
  	unless		=> '/usr/bin/dpkg -l | /bin/grep -c installatron',
  	onlyif		=> '/bin/ls /root/installatron-server_latest_all.deb | /bin/grep -c installatron',
  	require    	=> File['/etc/profile.d/installatron-key.sh'],
  }


  file { '/etc/apache2/sites-enabled/000-default':
  	source		=> "puppet:///modules/atomia/installatron/000-default",
  	require 	=> Package["apache2"],
  	notify		=> Service["apache2"]
  }

  file { '/etc/profile.d/installatron-key.sh':
  	mode  	=> "0755",
  	content => "export KEY=${license_key}",
  }

  file { '/usr/local/installatron/http/index.php':
 	mode 	=> "0644",
  }
}
