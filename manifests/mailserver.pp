## Atomia postfix and dovecot resource server

### Deploys and configures a server running Postfix and Dovecot for hosting customer email.

### Variable documentation
#### provisioning_host: The IP or hostname of the server running automation server, used for the automation server MySQL user to restrict access.
#### is_master: Toggles if we are provisioning the master mailserver node (with the main user database) or a slave node (with a replicated database).
#### master_ip: The IP of the master mailserver.
#### agent_password: The password for the MySQL user that automation server provisions mail users through.
#### slave_password: The password for the MySQL user with the name slave_user that the mail user database replication uses.
#### install_antispam: Toggles if we are to configure spam and virus filtering.
#### cluster_ip: The virtual IP of the mail cluster.
#### mail_share_nfs_location: The location of the NFS share for mailbox content. Leave empty if using the default storage setup with GlusterFS.
#### use_nfs3: Toggles if we are to use NFSv3 for the NFS mount.
#### skip_mount: Toggles if we are to mount the content share or not.
#### mailbox_base: The mountpoint where the mailbox content share is mounted.
#### mysql_server_id: The server id of the MySQL server that is used for mail user information.
#### mysql_root_password: The password for the MySQL root user.
#### ssl_certificate_name_base: The name used to construct the paths to the Postfix TLS certificate and key.
#### postfix_my_networks: Which networks should Postfix relay all mails from.
#### postfix_message_size_limit: The maximum message size limit.
#### postfix_override_main_cf: If set will override the template used to generate the postfix main.cf configuration file.
#### postfix_override_master_cf: If set will override the postfix master.cf configuration file.
#### dovecot_override_config: If set will override the dovecot.conf configuration file.

### Validations
##### provisioning_host: ^[0-9.a-z%-]+$
##### is_master(advanced): %hide
##### master_ip(advanced): %ip
##### agent_password(advanced): %password
##### slave_password(advanced): %password
##### install_antispam(advanced): %int_boolean
##### cluster_ip: %ip
##### mail_share_nfs_location(advanced): %nfs_share
##### use_nfs3(advanced): %int_boolean
##### skip_mount(advanced): %int_boolean
##### mailbox_base(advanced): %path
##### mysql_server_id(advanced): ^[0-9]+$
##### mysql_root_password(advanced): %password
##### ssl_certificate_name_base(advanced): ^[a-z0-9_-]+$
##### postfix_my_networks(advanced): ^[0-9a-fA-F:./]+$
##### postfix_message_size_limit(advanced): ^[0-9]+$
##### postfix_override_main_cf(advanced): ^.*$
##### postfix_override_master_cf(advanced): ^.*$
##### dovecot_override_config(advanced): ^.*$

class atomia::mailserver (
  $provisioning_host          = '%',
  $is_master                  = '1',
  $master_ip                  = $ipaddress,
  $agent_password,
  $slave_password,
  $install_antispam           = '1',
  $cluster_ip                 = '',
  $mail_share_nfs_location    = '',
  $use_nfs3                   = '1',
  $skip_mount                 = '0',
  $mailbox_base               = '/storage/mailcontent',
  $mysql_server_id            = '',
  $mysql_root_password,
  $ssl_certificate_name_base  = 'ssl-cert-snakeoil',
  $postfix_my_networks        = '127.0.0.0/8',
  $postfix_message_size_limit = '30720000',
  $postfix_override_main_cf   = '',
  $postfix_override_master_cf = '',
  $dovecot_override_config    = ''
) {

  case $::osfamily {
    #Debian is default
    default : {
      $required_packages = [
        'dovecot-common',
        'dovecot-imapd',
        'dovecot-mysql',
        'dovecot-pop3d',
        'libdbd-mysql-perl',
        'libemail-valid-perl',
        'liblog-log4perl-perl',
        'libmail-sendmail-perl',
        'libmime-encwords-perl',
        'postfix-mysql',
      ]

      $postfix_mysql_package = 'postfix-mysql'
      $dovecot_package       = 'dovecot-common'
      $clamav_package        = 'clamav-daemon'

      $required_packages_antispam = [
        'amavisd-new',
        'arj',
        'bzip2',
        'cabextract',
        'clamav-daemon',
        'cpio',
        'file',
        'gzip',
        'libnet-dns-perl',
        'nomarch',
        'pax',
        'pyzor',
        'rar',
        'razor',
        'spamassassin',
        'unrar',
        'unzip',
        'zip',
        'zoo'
      ]
    }
    'Redhat' : {
      $required_packages = [
        'dovecot',
        'dovecot-mysql',
        'perl-DBD-MySQL',
        'perl-Log-Log4perl',
        'perl-MIME-EncWords',
        'perl-Mail-Sendmail',
        'perl-Email-Valid',
        'postfix',
      ]

      $postfix_mysql_package = 'postfix'
      $dovecot_package       = 'dovecot'
      $clamav_package        = 'clamav-scanner'

      $required_packages_antispam = [
        'amavisd-new',
        'clamav-scanner',
        'perl-Net-DNS',
        'spamassassin',
        'unar',
        'unzip',
        'zip',
      ]
    }
  }

  package { $required_packages: ensure => installed }

  if $install_antispam == '1' {

    package { $required_packages_antispam: ensure => installed }

    if $::lsbdistrelease == '12.04' {
      package { 'lha': ensure => installed }
    } else {
      package { 'lhasa': ensure => installed }
    }
  }

  $db_hosts             = '127.0.0.1'
  $db_user              = 'vmail'
  $db_user_provisioning = 'postfix_agent'
  $db_name              = 'vmail'
  $db_pass              = $agent_password

  if $mail_share_nfs_location != '' {
    atomia::nfsmount { 'mount_mail_content':
      use_nfs3     => '1',
      mount_point  => $mailbox_base,
      nfs_location => $mail_share_nfs_location,
      require      => File[$mailbox_base],
    }

    $mailbox_base_array = path_split($mailbox_base)
    file { $mailbox_base_array:
      ensure  => directory,
      owner   => 'virtual',
      group   => 'virtual',
      mode    => '0775',
      require => User['virtual']
    }
  } else {
    if $::osfamily == 'Redhat' {
      warning('RedHat-based servers with glusterfs are not supported yet')
    } else {
      $internal_zone = hiera('atomia::internaldns::zone_name','')
      package { 'glusterfs-client': ensure => present, }

      if !defined(File['/storage']) {
        file { '/storage':
          ensure => directory,
        }
      }

      fstab::mount { "${mailbox_base}":
        ensure  => 'mounted',
        device  => "gluster.${internal_zone}:/mail_volume",
        options => 'defaults,_netdev',
        fstype  => 'glusterfs',
        require => [Package['glusterfs-client'],File['/storage']],
      }
    }
  }

  if $mysql_server_id == ''
  {
    $mysql_server_id_from_hostname = inline_template('<%= @hostname.scan(/\d+/).first %>')
    if $mysql_server_id_from_hostname == '' {
      if $is_master == '1' {
        $mysql_id = '1'
      } else {
        $mysql_id = '2'
      }
    } else {
      $mysql_id = $mysql_server_id_from_hostname
    }
  }
  else
  {
    $mysql_id = $mysql_server_id
  }

  if $is_master == '1' {
    class { 'mysql::server':
      restart                 => true,
      root_password           => $mysql_root_password,
      remove_default_accounts => true,
      override_options        => {
        'mysqld' => {
          'server_id'    => $mysql_id,
          'log_bin'      => '/var/log/mysql/mysql-bin.log',
          'binlog_do_db' => $db_name,
          'bind_address' => '*'
        }
      }
    }

    mysql_user { 'create-automationserver-user':
      ensure        => 'present',
      name          => "${db_user_provisioning}@${provisioning_host}",
      password_hash => mysql_password($db_pass),
      require       => Class[Mysql::Server::Service],
    }

    mysql_grant { "${db_user_provisioning}@${provisioning_host}/${db_name}.*":
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['ALL'],
      table      => "${db_name}.*",
      user       => "${db_user_provisioning}@${provisioning_host}",
      require    => Mysql_database['create-vmail-database']
    }

    mysql_user { 'create-slave-user':
      ensure        => 'present',
      name          => 'slave_user@%',
      password_hash => mysql_password($slave_password),
      require       => Class[Mysql::Server::Service],
    }

    mysql_grant { 'slave_user@%/*.*':
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['ALL', 'REPLICATION SLAVE'],
      table      => '*.*',
      user       => 'slave_user@%',
      require    => Class[Mysql::Server::Service],
    }

    file { '/etc/postfix/mysql.schema.sql':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/atomia/mailserver/mysql.schema.sql',
      require => Package[$postfix_mysql_package]
    }

    file { '/etc/postfix/update_vmail_database_for_quota.sql':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/atomia/mailserver/update_vmail_database_for_quota.sql',
      require => Package[$postfix_mysql_package]
    }

    exec { 'setup-master':
      command => '/etc/postfix/setup_database.sh master',
      require => [
        File['/etc/postfix/setup_database.sh'],
        Class[Mysql::Server::Service],
        File['/etc/postfix/mysql.schema.sql'],
        Mysql_database['create-vmail-database'],
        Mysql_grant['slave_user@%/*.*']
      ],
      unless  => '/etc/postfix/setup_database.sh master_is_done',
    }

  } else {
    # Slave config
    class { 'mysql::server':
      restart                 => true,
      root_password           => $mysql_root_password,
      remove_default_accounts => true,
      override_options        => {
        mysqld => {
          'server_id'    => $mysql_id,
          'log_bin'      => '/var/log/mysql/mysql-bin.log',
          'binlog_do_db' => $db_name,
          'bind_address' => '*'
        }
      }
    }

    exec { 'setup-slave':
      command => '/etc/postfix/setup_database.sh slave',
      require => [
        File['/etc/postfix/setup_database.sh'],
        Class[Mysql::Server::Service],
        Mysql_database['create-vmail-database'],
        Mysql_grant["${db_user}@127.0.0.1/${db_name}.*"]
      ],
      unless  => '/etc/postfix/setup_database.sh slave_is_done',
    }
  }

  mysql_database { 'create-vmail-database':
    ensure  => 'present',
    name    => $db_name,
    require => Class[Mysql::Server::Service],
  }

  mysql_user { 'create-vmail-user':
    ensure        => 'present',
    name          => "${db_user}@127.0.0.1",
    password_hash => mysql_password($db_pass),
    require       => Class[Mysql::Server::Service],
  }

  mysql_grant { "${db_user}@127.0.0.1/${db_name}.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => "${db_name}.*",
    user       => "${db_user}@127.0.0.1",
    require    => Mysql_database['create-vmail-database']
  }

  file { '/etc/postfix/setup_database.sh':
    owner   => 'root',
    group   => 'root',
    mode    => '0500',
    content => template('atomia/mailserver/setup_database.sh.erb'),
    require => Package[$postfix_mysql_package]
  }

  if $postfix_override_main_cf != '' {
    $postfix_main_cf_content = template_inline($postfix_override_main_cf)
  } else {
    $postfix_main_cf_content = template('atomia/mailserver/main.cf')
  }

  file { '/etc/postfix/main.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $postfix_main_cf_content,
    require => Package[$postfix_mysql_package]
  }

  if $postfix_override_master_cf == '' {
    file { '/etc/postfix/master.cf':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/atomia/mailserver/master.cf',
      require => Package[$postfix_mysql_package]
    }
  } else {
    file { '/etc/postfix/master.cf':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => $postfix_override_master_cf,
      require => Package[$postfix_mysql_package]
    }
  }

  file { '/etc/postfix/mysql_relay_domains_maps.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/mysql_relay_domains_maps.cf.erb'),
    require => Package[$postfix_mysql_package],
    notify  => Service['postfix'],
  }

  file { '/etc/postfix/mysql_virtual_alias_domains.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/mysql_virtual_alias_domains.cf.erb'),
    require => Package[$postfix_mysql_package],
    notify  => Service['postfix'],
  }

  file { '/etc/postfix/mysql_virtual_alias_maps.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/mysql_virtual_alias_maps.cf.erb'),
    require => Package[$postfix_mysql_package],
    notify  => Service['postfix'],
  }

  file { '/etc/postfix/mysql_virtual_domains_maps.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/mysql_virtual_domains_maps.cf.erb'),
    require => Package[$postfix_mysql_package],
    notify  => Service['postfix'],
  }

  file { '/etc/postfix/mysql_virtual_mailbox_maps.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/mysql_virtual_mailbox_maps.cf.erb'),
    require => Package[$postfix_mysql_package],
    notify  => Service['postfix'],
  }

  file { '/etc/postfix/mysql_virtual_transport.cf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/mysql_virtual_transport.cf.erb'),
    require => Package[$postfix_mysql_package],
    notify  => Service['postfix'],
  }

  file { '/etc/dovecot/dovecot-sql.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/mailserver/dovecot-sql.conf.erb'),
    require => Package[$dovecot_package],
  }

  if $dovecot_override_config == '' {
    file { '/etc/dovecot/dovecot.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/atomia/mailserver/dovecot.conf',
      require => Package[$dovecot_package],
    }
  } else {
    file { '/etc/dovecot/dovecot.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => $dovecot_override_config,
      require => Package[$dovecot_package],
    }
  }

  file { '/usr/bin/vacation.pl':
    owner   => 'root',
    group   => 'virtual',
    mode    => '0750',
    content => template('atomia/mailserver/vacation.pl'),
  }

  file { '/var/log/vacation.log':
    ensure => present,
    owner  => 'virtual',
    group  => 'virtual',
    mode   => '0640',
  }

  file { '/etc/mailname':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $::hostname,
  }

  file { '/etc/maildomain':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $::domain,
  }

  exec { 'gen-key':
    command  => '/usr/bin/openssl genrsa -out /etc/dovecot/ssl.key 2048; chown root:root /etc/dovecot/ssl.key; chmod 0700 /etc/dovecot/ssl.key',
    creates  => '/etc/dovecot/ssl.key',
    provider => 'shell',
    require  => Package[$dovecot_package],
  }

  exec { 'gen-csr':
    command => '/usr/bin/openssl req -new -batch -key /etc/dovecot/ssl.key -out /etc/dovecot/ssl.csr',
    creates => '/etc/dovecot/ssl.csr',
    onlyif  => '/usr/bin/test -f /etc/dovecot/ssl.key',
    require => [ Exec['gen-key'] ],
  }

  exec { 'gen-cert':
    command => '/usr/bin/openssl x509 -req -days 3650 -in /etc/dovecot/ssl.csr -signkey /etc/dovecot/ssl.key -out /etc/dovecot/ssl.crt',
    creates => '/etc/dovecot/ssl.crt',
    onlyif  => '/usr/bin/test -f /etc/dovecot/ssl.csr',
    require => [ Exec['gen-csr'] ],
  }

  service { 'postfix':
    ensure    => running,
    enable    => true,
    subscribe => [Package[$postfix_mysql_package], File['/etc/postfix/main.cf'], File['/etc/postfix/master.cf']]
  }

  service { 'dovecot':
    ensure    => running,
    enable    => true,
    subscribe => [Package[$dovecot_package], File['/etc/dovecot/dovecot.conf'], File['/etc/dovecot/dovecot-sql.conf']]
  }

  group { 'virtual':
    ensure => present,
    gid    => 2000,
  }

  user { 'virtual':
    ensure     => present,
    uid        => 2000,
    gid        => 2000,
    home       => '/var/spool/mail',
    comment    => 'virtual',
    groups     => 'virtual',
    membership => minimum,
    shell      => '/bin/bash',
    require    => Group['virtual'],
  }

  if $install_antispam == '1' {
    # Configure Spam and Virus filtering

    user { 'clamav':
      ensure  => 'present',
      groups  => 'amavis',
      require => [Package['amavisd-new'], Package[$clamav_package]],
    }

    user { 'amavis':
      ensure  => 'present',
      groups  => 'clamav',
      require => [Package['amavisd-new'], Package[$clamav_package]],
    }

    exec { 'enable-spamd':
      command => "/bin/sed -i /etc/default/spamassassin -e 's/ENABLED=0/ENABLED=1/' && /bin/sed -i /etc/default/spamassassin -e 's/CRON=0/CRON=1/'",
      require => Package['spamassassin'],
      unless  => '/bin/sh -c "grep ENABLED=1 /etc/default/spamassassin && grep CRON=1 /etc/default/spamassassin"',
      notify  => [ Service['spamassassin'] ]
    }

    service { 'spamassassin':
      ensure  => running,
      enable  => true,
      require => Package['spamassassin'],
    }

    service { 'amavis':
      ensure    => running,
      enable    => true,
      subscribe => [File['/etc/amavis/conf.d/15-content_filter_mode']],
      require   => [ Package['spamassassin'], Package['amavisd-new'] ],
    }

    file { '/etc/amavis/conf.d/15-content_filter_mode':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/atomia/mailserver/15-content_filter_mode',
      require => Package['amavisd-new'],
    }
  }
}
