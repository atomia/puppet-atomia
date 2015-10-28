class atomia::glusterfs (
	$web_content_volume_size			= "100G",
	$configuration_volume_size		=	"10G",
	$mail_volume_size							= "100G",
	$peers												= "",
	$physical_volume							= "/dev/sdb"
) {

	package { 'python-software-properties': ensure => present }
	package { 'xfsprogs': ensure => present }
	package { 'lvm2: ensure => present }
	class { 'glusterfs::server':
  	peers => [ 
    	'192.168.1.114',
			'192.168.1.116'
  	],
	}

	file { [ '/export', '/export/web', '/export/mail', '/export/config' ]:
  	seltype => 'usr_t',
  	ensure  => directory,
	}

	exec { "create-physical-volume":
		command => "/sbin/pvcreate ${physical_volume}",
		onlyif 	=> "/sbin/pvdisplay | /bin/grep ${physical_volume} >/dev/null 2>&1"
		require	=> Package['lvm2']
	}

  exec { "create-volume-group":
    command => "/sbin/vgcreate gluster ${physical_volume}",
    onlyif  => "/sbin/vgs | /bin/grep gluster  >/dev/null 2>&1"
    require => Exec["create-physical-volume"]
  }


	exec { 'create-web-lv':
  	command => "/sbin/lvcreate -L ${web_content_volume_size} -n web gluster",
		creates = '/dev/gluster/web',
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
    creates = '/dev/gluster/mail',
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
    command => "/sbin/lvcreate -L ${config_volume_size} -n config gluster",
    creates = '/dev/gluster/config',
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
	# TODO: need to be smart about this
	glusterfs::volume { 'gv0':
  	create_options => 'replica 2 192.168.0.1:/export/gv0 192.168.0.2:/export/gv0',
  	require        => Mount['/export/web'],
	}	


	# Configure Samba + CTDB

#	exec {"add-gluster-repo":
#		command => "/usr/bin/add-apt-repository ppa:gluster/glusterfs-3.5",
#		notify => Exec["apt-get-update"]
# }

#	exec { "apt-get-update": 
#		command => "/usr/bin/apt-get update", 
#		refreshonly => true
#	}

#	package { 'glusterfs-server':
#		ensure => present,
#		require => Exec["add-gluster-repo"]
#	}
#
#	package { 'glusterfs-client':
#		ensure => present,
#		require => Exec["add-gluster-repo"]
#	}
#
#	package { 'xfsprogs' :
#		ebsure => present
#	}


# If we are the first node we should probe for our peers
#if $fqdn = $peers[0] {

#}
#	$peers.each |$peer| {
#		if $peer != $fqdn {
#	
#			exec { "wait-for-peer":
#				command =>  "while [ `sleep 5; /usr/sbin/gluster peer probe ${peer} | /usr/bin/awk '{print $4}'` == '0' ]; do echo 'peers missing' ; done",
#			}
#		
#		}
#	}
#	exec { "wait-for-peer":
#		command =>  "while [ `sleep 5; /usr/sbin/gluster peer status | /usr/bin/awk '{print $4}'` == '0' ]; do echo 'peers missing' ; done",
#	}
}
