## Atomia GlusterFS

### Deploys and configures a GlusterFS cluster

### Variable documentation
#### web_content_volume_size: The size of the volume used for website content (customer websites)
#### configuration_volume_size: The size of the volume used for shared configurations
#### mail_volume_size: The size of the volume used for the mail cluster
#### peers: Hostname/IP of all the peers in the cluster
#### physical_volume: The physical volume on the server to create storage volumes on


### Validations
##### web_content_volume_size: ^[0-9]+G$
##### configuration_volume_size: ^[0-9]+G$
##### mail_volume_size: ^[0-9]+G$
##### peers(advanced): .*
##### physical_volume: .*


class atomia::glusterfs (
	$web_content_volume_size			= "100G",
	$configuration_volume_size		=	"10G",
	$mail_volume_size							= "100G",
	$peers												= "$fqdn",
	$physical_volume							= "/dev/sdb"
) {

	# Set ip correctly when on ec2
  if $ec2_public_ipv4 {
    $public_ip = $ec2_public_ipv4
  } else {
    $public_ip = $ipaddress_eth0
  }

	$netbios_domain_name = hiera('atomia::active_directory::netbios_domain_name')
	$domain_name = hiera('atomia::active_directory::domain_name')
	$zone_name = hiera('atomia::internaldns::zone_name')
	$ad_password = hiera('atomia::active_directory::windows_admin_password')
	host { 'domain-member-host':
		name		=> "${::hostname}.$domain_name",
		ip	=> "${::ipaddress_eth0}"
	}

	@@bind::a { "${fqdn}-gluster-dns":
	  ensure    => 'present',
	  zone      => hiera('atomia::internaldns::zone_name'),
	  ptr       => false,
	  hash_data => {
	    'gluster' => { owner => "${public_ip}" },
	  },
	}


	$peers_arr = split($peers,',')
	$peers_size = size($peers_arr)

	package { 'python-software-properties': ensure => present }
	package { 'xfsprogs': ensure => present }
	package { 'lvm2': ensure => present }
	package { 'samba': ensure => present }
	package { 'ctdb': ensure => present}

	class { 'glusterfs::server':
  	peers => $peers_arr,
	}

	file { [ '/export', '/export/web', '/export/mail', '/export/config' ]:
  	seltype => 'usr_t',
  	ensure  => directory,
	}

	exec { "create-physical-volume":
		command => "/sbin/pvcreate ${physical_volume}",
		unless 	=> "/sbin/pvdisplay | /bin/grep ${physical_volume} >/dev/null 2>&1",
		require	=> Package['lvm2']
	}

  exec { "create-volume-group":
    command => "/sbin/vgcreate gluster ${physical_volume}",
    unless  => "/sbin/vgs | /bin/grep gluster  >/dev/null 2>&1",
    require => Exec["create-physical-volume"]
  }


	exec { 'create-web-lv':
  	command => "/sbin/lvcreate -L ${web_content_volume_size} -n web gluster",
		creates => '/dev/gluster/web',
  	notify  => Exec['mkfs web'],
		require	=> Exec["create-volume-group"]
	}

	exec { 'mkfs web':
  	command     => '/sbin/mkfs.xfs -i size=512 /dev/gluster/web',
  	require     => [ Package['xfsprogs'], Exec['create-web-lv'] ],
  	refreshonly => true,
	}

	mount { '/export/web':
  	device  => '/dev/gluster/web',
  	fstype  => 'xfs',
  	options => 'defaults',
  	ensure  => mounted,
  	require => [ Exec['mkfs web'], File['/export/web'] ],
	}

  exec { 'create-mail-lv':
    command => "/sbin/lvcreate -L ${mail_volume_size} -n mail gluster",
    creates => '/dev/gluster/mail',
    notify  => Exec['mkfs mail'],
    require => Exec["create-volume-group"]
  }

  exec { 'mkfs mail':
    command     => '/sbin/mkfs.xfs -i size=512 /dev/gluster/mail',
    require     => [ Package['xfsprogs'], Exec['create-mail-lv'] ],
    refreshonly => true,
  }

  mount { '/export/mail':
    device  => '/dev/gluster/mail',
    fstype  => 'xfs',
    options => 'defaults',
    ensure  => mounted,
    require => [ Exec['mkfs mail'], File['/export/mail'] ],
  }

  exec { 'create-config-lv':
    command => "/sbin/lvcreate -L ${configuration_volume_size} -n config gluster",
    creates => '/dev/gluster/config',
    notify  => Exec['mkfs config'],
    require => Exec["create-volume-group"]
  }

  exec { 'mkfs config':
    command     => '/sbin/mkfs.xfs -i size=512 /dev/gluster/config',
    require     => [ Package['xfsprogs'], Exec['create-config-lv'] ],
    refreshonly => true,
  }

  mount { '/export/config':
    device  => '/dev/gluster/config',
    fstype  => 'xfs',
    options => 'defaults',
    ensure  => mounted,
    require => [ Exec['mkfs config'], File['/export/config'] ],
  }


	# Create Gluster volumes
	file { '/export/web/vol1':
		ensure => directory,
		require => Mount["/export/web"]
	}

	file { '/export/mail/vol1':
		ensure => directory,
		require => Mount["/export/mail"]
	}

	file { '/export/config/vol1':
		ensure => directory,
		require => Mount["/export/config"]
	}

	exec { "gluster volume create /export/web":
    command => "/usr/sbin/gluster volume create web_volume replica ${peers_size} ${peers_arr[0]}:/export/web/vol1 ${peers_arr[1]}:/export/web/vol1",
    creates => "/var/lib/glusterd/vols/web_volume",
    require => [ Class['glusterfs::server'], File['/export/web/vol1'] ],
		unless	=> "/usr/bin/test `/usr/sbin/gluster peer status | /bin/grep -c Hostname` -eq ${peers_size};",
		notify	=> Exec['start web volume'],
  }

	exec { 'start web volume':
		command => '/usr/sbin/gluster volume start web_volume',
		refreshonly	=> true
	}

	exec { "gluster volume create /export/mail":
    command => "/usr/sbin/gluster volume create mail_volume replica ${peers_size} ${peers_arr[0]}:/export/mail/vol1 ${peers_arr[1]}:/export/mail/vol1",
    creates => "/var/lib/glusterd/vols/mail_volume",
    require => [ Class['glusterfs::server'], File['/export/mail/vol1'] ],
		unless	=> "/usr/bin/test `/usr/sbin/gluster peer status | /bin/grep -c Hostname` -eq ${peers_size};",
		notify	=> Exec['start mail volume'],
  }

	exec { 'start mail volume':
		command => '/usr/sbin/gluster volume start mail_volume',
		refreshonly	=> true
	}

	exec { "gluster volume create /export/config":
    command => "/usr/sbin/gluster volume create config_volume replica ${peers_size} ${peers_arr[0]}:/export/config/vol1 ${peers_arr[1]}:/export/config/vol1",
    creates => "/var/lib/glusterd/vols/config_volume",
    require => [ Class['glusterfs::server'], File['/export/config/vol1'] ],
		unless	=> "/usr/bin/test `/usr/sbin/gluster peer status | /bin/grep -c Hostname` -eq ${peers_size};",
		notify	=> Exec['start config volume'],
  }

	exec { 'start config volume':
		command => '/usr/sbin/gluster volume start config_volume',
		refreshonly	=> true
	}

	# Mount Glusetr volumes
	file { '/storage':
		ensure	=> directory,
	}

	class { 'fstab' : }

	fstab::mount { '/storage/content':
	  ensure  => 'mounted',
	  device  => 'gluster.atomia.internal:web_volume',
	  options => 'defaults,_netdev',
	  fstype  => 'glusterfs',
	}

	fstab::mount { '/storage/configuration':
	  ensure  => 'mounted',
	  device  => 'gluster.atomia.internal:config_volume',
	  options => 'defaults,_netdev',
	  fstype  => 'glusterfs',
	}

	# Configure Samba
	file { '/etc/samba/smb.conf':
		content => template('atomia/glusterfs/smb.conf.erb'),
		require	=> Package['samba']
	}

	file { '/etc/samba/smbusers':
		ensure	=> present,
		content => "root = ${$netbios_domain_name}\\Administrator"
	}

	exec {'samba-join-domain':
		command	=> "/usr/bin/net ads join -U WindowsAdmin%${ad_password}",
		onlyif => "/usr/bin/net ads status -U WindowsAdmin%${ad_password} | /bin/grep 'No machine' >/dev/null 2>&1"
	}
#WindowsAdmin
}
