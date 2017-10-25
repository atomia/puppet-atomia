## Atomia Storage

### Deploys and configures a Storage node

### Variable documentation
#### web_content_volume_size: The size of the volume used for website content (customer websites) (eg. 500G)
#### configuration_volume_size: The size of the volume used for shared configurations (eg. 20G)
#### mail_volume_size: The size of the volume used for the mail cluster (eg. 600G)
#### physical_volume: The physical volume on the server to create storage volumes on
#### vg_name: The name of the volume group to be created to store data
#### ip_range: The ip range of the machines which should be able to access NFS storage

### Validations
##### web_content_volume_size: ^[0-9]+G$
##### configuration_volume_size: ^[0-9]+G$
##### mail_volume_size: ^[0-9]+G$
##### physical_volume: .*
##### vg_name: .*
##### ip_range: .*

class atomia::storage (
  $web_content_volume_size   = '100G',
  $configuration_volume_size = '10G',
  $mail_volume_size          = '100G',
  $physical_volume           = '/dev/sdb',
  $vg_name                   = 'storage',
  $ip_range                  = '192.168.33.0/24',
) {

  # Set ip correctly when on ec2
  if !$public_ip {
    if $::ec2_public_ipv4 {
      $public_ip = $::ec2_public_ipv4
    } elsif $::ipaddress_eth0 {
      $public_ip = $::ipaddress_eth0
    }
    else {
      $public_ip = $::ipaddress
    }
  }

  $netbios_domain_name = hiera('atomia::active_directory::netbios_domain_name')
  $domain_name         = hiera('atomia::active_directory::domain_name')
  $ad_password         = hiera('atomia::active_directory::windows_admin_password')

  host { 'domain-member-host':
    name => "${::hostname}.${domain_name}",
    ip   => $::ipaddress_eth0
  }

  if !$::vagrant {
    $internal_zone       = hiera('atomia::internaldns::zone_name')
    $storage_hostname    = "storage.${internal_zone}"
    @@bind::a { "${fqdn}-storage-dns":
      ensure    => 'present',
      zone      => $internal_zone,
      ptr       => false,
      hash_data => {
        'storage' => {
          owner => $::ipaddress },
      },
    }
  } else {
    $storage_hostname    = '192.168.33.38'
  }

  package { 'python-software-properties': ensure => present }
  package { 'xfsprogs': ensure => present }
  package { 'lvm2': ensure => present }
  package { 'samba': ensure => present }

  file { '/export': ensure => directory, }
  ->
  file { '/export/config':
    ensure  => directory,
    require => File['/export'],
    mode    => '0711'
  }
  ->
  file { '/export/mail':
    ensure  => directory,
    require => File['/export'],
    mode    => '0755'
  }
  ->
  file { '/export/web':
    ensure  => directory,
    require => File['/export'],
    mode    => '0711'
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

  class { '::nfs':
    server_enabled => true
  }

  nfs::server::export{ '/export/config':
     ensure  => 'mounted',
     clients => "${ip_range}(rw,async,no_root_squash,no_subtree_check)",
     require => [ File['/export/config'] ],
  }
  nfs::server::export{ '/export/web':
     ensure  => 'mounted',
     clients => "${ip_range}(rw,async,no_root_squash,no_subtree_check)",
     require => [ File['/export/web'] ],
  }
  nfs::server::export{ '/export/mail':
     ensure  => 'mounted',
     clients => "${ip_range}(rw,async,no_root_squash,no_subtree_check)",
     require => [ File['/export/mail'] ],
  }

  # Configure Samba
  # TODO: Investigate why on vagrant when accessing the share you get ACCESS_DENIED for \lsarpc before you
  # TODO: add lsarpc to the domain controller Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options
  # TODO: policy and then gpupdate /force
  file { '/etc/samba/smb.conf':
    content => template('atomia/storage/smb.conf.erb'),
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

}
