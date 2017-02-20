## Atomia GlusterFS

### Deploys and configures a GlusterFS cluster

### Variable documentation
#### web_content_volume_size: The size of the volume used for website content (customer websites)
#### configuration_volume_size: The size of the volume used for shared configurations
#### mail_volume_size: The size of the volume used for the mail cluster
#### peers: Hostname of all the peers in the cluster (NOT the master node)
#### physical_volume: The physical volume on the server to create storage volumes on
#### vg_name: The name of the volume group to be created for use with Gluster
#### quota_management_ssh_key: The SSH key to allow quota management for
#### gluster_hostname: DNS name containing a records for all gluster nodes

### Validations
##### web_content_volume_size: ^[0-9]+G$
##### configuration_volume_size: ^[0-9]+G$
##### mail_volume_size: ^[0-9]+G$
##### peers: .*
##### physical_volume: .*
##### vg_name: .*
##### quota_management_ssh_key: (^$|^ssh-rsa )
##### gluster_hostname: .*

class atomia::glusterfs (
  $web_content_volume_size   = '4G',
  $configuration_volume_size = '1G',
  $mail_volume_size          = '4G',
  $peers                     = $fqdn,
  $physical_volume           = '/dev/xvdb',
  $vg_name                   = 'gluster',
  $quota_management_ssh_key  = '',
  $gluster_hostname          = ''
) {

  $is_first_node = hiera('atomia::glusterfs::is_first_node', 0)

  # Set ip correctly when on ec2
  if defined('$::ec2_public_ipv4') {
    # Fix resolv.conf on EC2
    $ad_ip = hiera('atomia::active_directory::master_ip', '8.8.8.8')
    file_line { 'dhclient-fix':
      path => '/etc/dhcp/dhclient.conf',
      line => "supersede domain-name-servers $ad_ip;",
      notify => Exec['reload dhcp']
    } ->
    exec {'reload dhcp':
      command => '/usr/bin/sudo dhclient -r; /usr/bin/sudo dhclient',
      subscribe => File_line['dhclient-fix'],
      refreshonly => true
    }
  }

  $netbios_domain_name = hiera('atomia::active_directory::netbios_domain_name')
  $domain_name         = hiera('atomia::active_directory::domain_name')
  $ad_password         = hiera('atomia::active_directory::windows_admin_password')

  $peers_arr = split($peers,',')
  $peers_size = size($peers_arr)

  package { 'python-software-properties': ensure => present }
  package { 'xfsprogs': ensure => present }
  package { 'lvm2': ensure => present }
  package { 'samba': ensure => present }
  package { 'ctdb': ensure => present }
  package { 'attr': ensure => present, require => [ Package['glusterfs-server'] ] }

  package { 'glusterfs-server': ensure => installed }
  ->
  service { 'glusterd':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    name      => 'glusterfs-server',
    require   => Package['glusterfs-server'],
  }

  if $is_first_node == 1 {
    $peers_arr.each | $p| {
        exec { "/usr/sbin/gluster peer probe $p":
          unless  => "/bin/egrep '^hostname.+=${p}$' /var/lib/glusterd/peers/*",
          require => Service['glusterfs-server'],
        }
      }
  }


  file { [ '/export', '/export/web', '/export/mail', '/export/config' ]:
    ensure  => directory,
    seltype => 'usr_t',
  }

  exec { 'create-physical-volume':
    command => "/sbin/pvcreate ${physical_volume}",
    unless  => "/sbin/pvdisplay | /bin/grep ${physical_volume} >/dev/null 2>&1",
    require => Package['lvm2']
  }

  exec { 'create-volume-group':
    command => "/sbin/vgcreate ${vg_name} ${physical_volume}",
    unless  => "/sbin/vgs |  awk '{print \$1}' | /bin/egrep ^${vg_name}\$  >/dev/null 2>&1",
    require => Exec['create-physical-volume']
  }


  exec { 'create-web-lv':
    command => "/sbin/lvcreate -L ${web_content_volume_size} -n web ${vg_name}",
    creates => "/dev/${vg_name}/web",
    notify  => Exec['mkfs web'],
    require => Exec['create-volume-group']
  }

  exec { 'mkfs web':
    command     => "/sbin/mkfs.xfs -i size=512 /dev/${vg_name}/web",
    require     => [ Package['xfsprogs'], Exec['create-web-lv'] ],
    refreshonly => true,
  }

  mount { '/export/web':
    ensure  => mounted,
    device  => "/dev/${vg_name}/web",
    fstype  => 'xfs',
    options => 'defaults',
    require => [ Exec['mkfs web'], File['/export/web'] ],
  }

  exec { 'create-mail-lv':
    command => "/sbin/lvcreate -L ${mail_volume_size} -n mail ${vg_name}",
    creates => "/dev/${vg_name}/mail",
    notify  => Exec['mkfs mail'],
    require => Exec['create-volume-group']
  }

  exec { 'mkfs mail':
    command     => "/sbin/mkfs.xfs -i size=512 /dev/${vg_name}/mail",
    require     => [ Package['xfsprogs'], Exec['create-mail-lv'] ],
    refreshonly => true,
  }

  mount { '/export/mail':
    ensure  => mounted,
    device  => "/dev/${vg_name}/mail",
    fstype  => 'xfs',
    options => 'defaults',
    require => [ Exec['mkfs mail'], File['/export/mail'] ],
  }

  exec { 'create-config-lv':
    command => "/sbin/lvcreate -L ${configuration_volume_size} -n config ${vg_name}",
    creates => "/dev/${vg_name}/config",
    notify  => Exec['mkfs config'],
    require => Exec['create-volume-group']
  }

  exec { 'mkfs config':
    command     => "/sbin/mkfs.xfs -i size=512 /dev/${vg_name}/config",
    require     => [ Package['xfsprogs'], Exec['create-config-lv'] ],
    refreshonly => true,
  }

  mount { '/export/config':
    ensure  => mounted,
    device  => "/dev/${vg_name}/config",
    fstype  => 'xfs',
    options => 'defaults',
    require => [ Exec['mkfs config'], File['/export/config'] ],
  }


  # Create Gluster volumes
  file { '/export/web/vol1':
    ensure  => directory,
    require => Mount['/export/web']
  }

  file { '/export/mail/vol1':
    ensure  => directory,
    require => Mount['/export/mail']
  }

  file { '/export/config/vol1':
    ensure  => directory,
    require => Mount['/export/config']
  }

  class { 'fstab' : }

  file { '/storage':
    ensure  => directory,
  }

  if($is_first_node == 1) {
    exec { 'gluster volume create /export/web':
      command => template('atomia/glusterfs/create_web_volume.erb'),
      creates => '/var/lib/glusterd/vols/web_volume',
      require => [ Package['glusterfs-server'], File['/export/web/vol1'] ],
      notify  => Exec['start web volume'],
    }
  }

  fstab::mount { '/storage/content':
    ensure  => 'mounted',
    device  => "${gluster_hostname}:/web_volume",
    options => 'defaults,_netdev',
    fstype  => 'glusterfs',
    require => [Exec['start web volume'], File['/storage']],
  }

  fstab::mount { '/storage/mailcontent':
    ensure  => 'mounted',
    device  => "${gluster_hostname}:/mail_volume",
    options => 'defaults,_netdev',
    fstype  => 'glusterfs',
    require => [Exec['start mail volume'], File['/storage']],
  }

  exec { 'start web volume':
    command     => '/usr/sbin/gluster volume start web_volume',
    refreshonly => true,
    notify      => Exec['enable web quota']
  }

  exec { 'enable web quota':
    command     => '/usr/sbin/gluster volume quota web_volume enable',
    refreshonly => true
  }

  if($is_first_node == 1) {
    exec { 'gluster volume create /export/mail':
      command => template('atomia/glusterfs/create_mail_volume.erb'),
      creates => '/var/lib/glusterd/vols/mail_volume',
      require => [ Package['glusterfs-server'], File['/export/mail/vol1'] ],
      notify  => Exec['start mail volume'],
    }
  }

  exec { 'start mail volume':
    command     => '/usr/sbin/gluster volume start mail_volume',
    refreshonly => true,
    notify      => Exec['enable mail quota']
  }

  exec { 'enable mail quota':
    command     => '/usr/sbin/gluster volume quota mail_volume enable',
    refreshonly => true
  }

  if($is_first_node == 1) {
    exec { 'gluster volume create /export/config':
      command => template('atomia/glusterfs/create_config_volume.erb'),
      creates => '/var/lib/glusterd/vols/config_volume',
      require => [ Package['glusterfs-server'], File['/export/config/vol1'] ],
      notify  => Exec['start config volume'],
    }
  }

  exec { 'start config volume':
    command     => '/usr/sbin/gluster volume start config_volume',
    refreshonly => true
  }

  fstab::mount { '/storage/configuration':
    ensure  => 'mounted',
    device  => "${gluster_hostname}:/config_volume",
    options => 'defaults,_netdev',
    fstype  => 'glusterfs',
    require => [Exec['start config volume'], File['/storage']],
  }

  # Configure Samba
  # TODO: Investigate why on vagrant when accessing the share you get ACCESS_DENIED for \lsarpc before you
  # TODO: add lsarpc to the domain controller Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options
  # TODO: policy and then gpupdate /force
  file { '/etc/samba/smb.conf':
    content => template('atomia/glusterfs/smb.conf.erb'),
    require => Package['samba']
  }

  file { '/etc/samba/smbusers':
    ensure  => present,
    content => "root = ${netbios_domain_name}\\Administrator,${netbios_domain_name}\\WindowsAdmin ",
    require => Package['samba'],
  }

  if $::vagrant {
    $windows_admin_username = 'Administrator'
  } else {
    $windows_admin_username = 'WindowsAdmin'
  }

  exec {'samba-join-domain':
    command => "/usr/bin/net ads join -U \"${windows_admin_username}%${ad_password}\"",
    unless  => "/usr/bin/net ads status -U \"${windows_admin_username}%${ad_password}\"  >/dev/null 2>&1",
    require => [File['/etc/samba/smb.conf'], File['/etc/samba/smbusers']]
  }

  if $quota_management_ssh_key != '' {
    user { 'quotamgmt':
      ensure  => present,
      uid     => 2250,
      gid     => 'nogroup',
      home    => '/home/quotamgmt',
      comment => '',
      shell   => '/bin/sh'
    }

    file { '/home/quotamgmt':
      ensure  => directory,
      owner   => 'quotamgmt',
      group   => 'nogroup',
      mode    => '0700',
      require => User['quotamgmt'],
    }

    file { '/home/quotamgmt/.ssh':
      ensure  => directory,
      owner   => 'quotamgmt',
      group   => 'nogroup',
      mode    => '0700',
      require => File['/home/quotamgmt'],
    }

    file { '/home/quotamgmt/.ssh/authorized_keys2':
      ensure  => file,
      owner   => 'quotamgmt',
      group   => 'nogroup',
      mode    => '0600',
      content => template('atomia/glusterfs/authorized_keys.erb'),
      require => File['/home/quotamgmt/.ssh'],
    }

    file { '/opt/atomia':
      ensure  => directory,
      owner   => 'quotamgmt',
      group   => 'nogroup',
      mode    => '0700',
      require => User['quotamgmt'],
    }

    file { '/opt/atomia/quotamgmt.sh':
      ensure  => directory,
      owner   => 'quotamgmt',
      group   => 'nogroup',
      mode    => '0700',
      source  => 'puppet:///modules/atomia/glusterfs/quotamgmt.sh',
      require => File['/opt/atomia'],
    }

    file { '/etc/sudoers.d/20_quotamgmt':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      source  => 'puppet:///modules/atomia/glusterfs/20_quotamgmt',
      require => Package['sudo'],
    }
  }
}
