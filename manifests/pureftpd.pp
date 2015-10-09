class atomia::pureftpd (
  $agent_user          = "pureftpd",
  $agent_password,
  $master_ip,
  $provisioning_host,
  $pureftpd_password,
  $ftp_cluster_ip,
  $content_share_nfs_location,
  $is_master           = 0,
  $pureftpd_slave_password,
  $ssl_enabled         = 0,
  $skip_mount          = 0,
  $skip_mysql          = 0,
  $content_mount_point = "/storage/content",
  $passive_port_range   = "49152 65534") {

  package { pure-ftpd-mysql: ensure => installed }
  package { xinetd: ensure => installed }

  $mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"

  if $skip_mount == 0 {
    atomia::nfsmount { 'mount_content':
      use_nfs3     => 1,
      mount_point  => '/storage/content',
      nfs_location => $content_share_nfs_location
    }
  }

  if $hostname == "ftp01" {
    if $skip_mysql == 0 {
      class { 'mysql::server':
        override_options => {
          mysqld => {
            'server_id'    => '1',
            'log_bin'      => '/var/log/mysql/mysql-bin.log',
            'binlog_do_db' => 'pureftpd',
            'bind_address' => $master_ip
          }
        }
      }
    }

    exec { 'grant-replicate-privileges':
      command => "$mysql_command -e \"GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY '$pureftpd_slave_password';FLUSH PRIVILEGES;\"",
      unless  => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'slave_user'\" mysql | grep slave_user",
      require => Class[Mysql::Server::Service]
    }

    exec { 'create-pureftpd-db':
      command => "$mysql_command -e \"CREATE DATABASE pureftpd\"",
      unless  => "$mysql_command -e \"SHOW DATABASES;\" | grep pureftpd",
      require => Class[Mysql::Server::Service]
    }

    exec { 'import-schema':
      command => "$mysql_command pureftpd < /etc/pure-ftpd/mysql.schema.sql",
      unless  => "$mysql_command -e \"use pureftpd; show tables;\" | grep users",
      onlyif  => "$mysql_command -e \"SHOW DATABASES;\" | grep pureftpd",
      require => Class[Mysql::Server::Service]
    }

    exec { 'grant-pureftpd-agent-privileges':
      command => "$mysql_command -e \"GRANT ALL ON pureftpd.* TO '$agent_user'@'%' IDENTIFIED BY '$agent_password'\"",
      unless  => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$agent_user' AND host = '%'\" mysql | grep $agent_user",
      onlyif  => "$mysql_command -e \"SHOW DATABASES;\" | grep pureftpd",
      require => Class[Mysql::Server::Service]
    }

    file { "/etc/pure-ftpd/mysql.schema.sql":
      owner   => root,
      group   => root,
      mode    => 400,
      source  => "puppet:///modules/atomia/pureftpd/mysql.schema.sql",
      require => Package["pure-ftpd-mysql"],
    }
  } else {
    # Slave config
    if $skip_mysql == 0 {
      class { 'mysql::server':
        override_options => {
          mysqld => {
            'server_id'    => '2',
            'log_bin'      => '/var/log/mysql/mysql-bin.log',
            'binlog_do_db' => 'pureftpd'
          }
        }
      }
    }

    exec { 'change-master':
      command => "$mysql_command -e \"CHANGE MASTER TO MASTER_HOST='$master_ip',MASTER_USER='slave_user', MASTER_PASSWORD='$pureftpd_slave_password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=107;START SLAVE;\"",
      unless  => "$mysql_command -e \"SHOW SLAVE STATUS\\G\" | grep -i waiting",
      require => Class[Mysql::Server::Service]
    }
  }

  exec { 'grant-pureftpd-privileges':
    command => "$mysql_command -e \"GRANT ALL ON pureftpd.* TO 'pureftpd'@'$fqdn' IDENTIFIED BY '$pureftpd_password'\"",
    unless  => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'pureftpd' AND host = '$fqdn'\" mysql | grep pureftpd",
    require => Class[Mysql::Server::Service]
  }

  file { "/etc/pure-ftpd/db/mysql.conf":
    owner   => root,
    group   => root,
    mode    => 400,
    content => template("atomia/pure-ftpd/mysqlsettings.cfg.erb"),
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/ChrootEveryone":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "yes",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/CreateHomeDir":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "yes",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/DontResolve":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "yes",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/MaxClientsNumber":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "150",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/DisplayDotFiles":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "yes",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/PassivePortRange":
    owner   => root,
    group   => root,
    mode    => 444,
    content => $passive_port_range,
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/LimitRecursion":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "15000 15",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  file { "/etc/pure-ftpd/conf/ForcePassiveIP":
    owner   => root,
    group   => root,
    mode    => 444,
    content => "$ftp_cluster_ip",
    require => Package["pure-ftpd-mysql"],
    notify  => Service["pure-ftpd-mysql"],
  }

  service { pure-ftpd-mysql:
    name      => pure-ftpd-mysql,
    pattern   => "pure-ftpd.*",
    enable    => true,
    ensure    => running,
    subscribe => [
      Package["pure-ftpd-mysql"],
      File["/etc/pure-ftpd/db/mysql.conf"],
      File["/etc/pure-ftpd/conf/ChrootEveryone"],
      File["/etc/pure-ftpd/conf/CreateHomeDir"],
      File["/etc/pure-ftpd/conf/DontResolve"],
      File["/etc/pure-ftpd/conf/PassivePortRange"]],
  }

  if $ssl_enabled != 0 {
    file { "/etc/ssl":
      ensure => directory,
      owner  => "root",
      group  => "root",
      mode   => 0600,
    }

    file { "/etc/ssl/private":
      ensure => directory,
      owner  => "root",
      group  => "root",
      mode   => 0600,
    }

    /*
     * file { "/etc/ssl/private/pure-ftpd.pem":
     * owner => "root",
     * group => "root",
     * mode  => 600,
     * content => "$ssl_cert_key$ssl_cert_file",
     *}
     */
    file { "/etc/pure-ftpd/conf/TLS":
      owner   => root,
      group   => root,
      mode    => 444,
      content => "1",
      require => Package["pure-ftpd-mysql"],
      notify  => Service["pure-ftpd-mysql"],
    }
  }

  service { xinetd:
    name      => xinetd,
    ensure    => running,
    subscribe => [
      Package["xinetd"]
    ]
  }

  augeas { "add-heathcheck-service":
    changes => [
        "ins service-name after /files/etc/services/service-name[last()]",
        "set /files/etc/services/service-name[last()] check_ftp_health",
        "set /files/etc/services/service-name[. = 'check_ftp_health']/port 9200",
        "set /files/etc/services/service-name[. = 'check_ftp_health']/protocol tcp"
    ],
    onlyif => "match /files/etc/services/service-name[. = 'check_ftp_health'] size == 0"
  }

  file { "/opt/check_ftp_health":
    owner   => nobody,
    group   => root,
    mode    => 744,
    source  => "puppet:///modules/atomia/pureftpd/check_ftp_health"
  }

  file { "/etc/xinetd.d/check_ftp_health":
    owner   => root,
    group   => root,
    source => "puppet:///modules/atomia/pureftpd/check_ftp_health_xinetd",
    notify => Service["xinetd"],
    require => Package["xinetd"]
  }
}
