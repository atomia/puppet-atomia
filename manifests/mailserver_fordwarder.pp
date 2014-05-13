class atomia::mailserver_fordwarder (
                $provisioning_host,
                $is_master = 0,
                $master_ip,
                $agent_password,
                $slave_password,
                $cluster_ip = ""
        ){
        package { postfix-mysql: ensure => installed }
        package { dovecot-common: ensure => installed }
        package { libmime-encwords-perl: ensure => installed }
        package { libemail-valid-perl: ensure => installed }
        package { libmail-sendmail-perl: ensure => installed }
        package { liblog-log4perl-perl: ensure => installed }
        package { libdbd-mysql-perl: ensure => installed }
        package { dovecot-imapd: ensure => installed }
        package { dovecot-pop3d: ensure => installed }
        package { dovecot-mysql: ensure => installed }

       

        $db_hosts = $ipaddress
        $db_user = "vmail"
        $db_user_smtp = "smtp_vmail"
        $db_user_dovecot = "dovecot_vmail"
        $db_name = "vmail"
        $db_pass = $agent_password


        $mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"
        $mysql_server_id = inline_template('<%= hostname.scan(/\d+/).first %>')

        if $is_master == 1{
                class { 'mysql::server':
                        override_options  => { 'mysqld' => {'server_id' => "$mysql_server_id", 'log_bin' => '/var/log/mysql/mysql-bin.log', 'binlog_do_db' => "$db_name", 'bind_address' => $master_ip}}
                }

                exec { 'grant-replicate-privileges':
                        command => "$mysql_command -e \"GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY '$slave_password';FLUSH PRIVILEGES\";",
                        unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'slave_user'\" mysql | /bin/grep slave_user",
                        require => Class[Mysql::Server::Service]
                }

                exec { 'create-postfix-db':
                        command => "$mysql_command -e \"CREATE DATABASE $db_name\"",
                        unless => "$mysql_command -e \"SHOW DATABASES;\" | /bin/grep $db_name",
                        require => Class[Mysql::Server::Service]
                }

                exec { 'import-schema':
                        command => "$mysql_command $db_name < /etc/postfix/mysql.schema.sql",
                        unless => "$mysql_command -e \"use $db_name; show tables;\" | /bin/grep user",
                        require => Class[Mysql::Server::Service]
                }

                exec { 'grant-postfix-db-user-privileges':
                        command => "$mysql_command -e \"CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%'\"",
                        unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$db_user' \" mysql | /bin/grep $db_user",
                        require => Class[Mysql::Server::Service]
                }

                exec { 'grant-postfix-provisioning-user-privileges':
                        command => "$mysql_command -e \"GRANT ALL ON $db_name.* TO 'postfix_agent'@'$provisioning_host' IDENTIFIED BY '$db_pass'\"",
                        unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'postfix_agent' AND host = '$provisioning_host'\" mysql | /bin/grep postfix_agent",
                        require => Class[Mysql::Server::Service]
                }


                exec { 'grant-postfix-smtp-db-user-privileges':
                        command => "$mysql_command -e \"GRANT ALL ON $db_name.* TO '$db_user_smtp'@'%' IDENTIFIED BY '$db_pass'\"",
                        unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$db_user_smtp' AND host = '%'\" mysql | /bin/grep $db_user_smtp",
                        require => Class[Mysql::Server::Service]
                }

                exec { 'grant-postfix-dovecpt-db-user-privileges':
                        command => "$mysql_command -e \"GRANT ALL ON $db_name.* TO '$db_user_dovecot'@'%' IDENTIFIED BY '$db_pass'\"",
                        unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$db_user_dovecot' AND host = '%'\" mysql| /bin/grep $db_user_dovecot",
                        require => Class[Mysql::Server::Service]
                }

        }
        else {
                # Slave config
                class { 'mysql::server':
                        override_options => { mysqld => { 'server_id' => "$mysql_server_id", 'log_bin' => '/var/log/mysql/mysql-bin.log', 'binlog_do_db' => "$db_name",'bind_address' => "$ipaddress" } }
                }

                exec { 'change-master':
                        command => "$mysql_command -e \"CHANGE MASTER TO MASTER_HOST='$master_ip',MASTER_USER='slave_user', MASTER_PASSWORD='$slave_password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=107;START SLAVE;\"",
                        unless => "$mysql_command -e \"SHOW SLAVE STATUS\" | grep slave_user",
                        require => Class[Mysql::Server::Service]
                }
        }

        file { "/etc/postfix/mysql.schema.sql":
                owner   => root,
                group   => root,
                mode    => 444,
                source  => "puppet:///modules/atomia/mailserver/mysql.schema.sql",
                require => Package["postfix-mysql"]
        }
        if !$atomia_mailman_installed {

                file { "/etc/postfix/main.cf":
                        owner   => root,
                        group   => root,
                        mode    => 444,
                        content  => template('atomia/mailserver/main.cf'),
                        require => Package["postfix-mysql"]
                }
        }

        file { "/etc/postfix/master.cf":
                owner   => root,
                group   => root,
                mode    => 444,
                source  => "puppet:///modules/atomia/mailserver/master.cf",
                require => Package["postfix-mysql"]
        }


        file { "/etc/postfix/mysql_relay_domains_maps.cf":
                owner   => root,
                group   => root,
                mode    => 444,
                content => template('atomia/mailserver/mysql_relay_domains_maps.cf.erb'),
                require => Package["postfix-mysql"]
        }

        file { "/etc/postfix/mysql_virtual_alias_maps.cf":
                owner   => root,
                group   => root,
                mode    => 444,
                content => template('atomia/mailserver/mysql_virtual_alias_maps.cf.erb'),
                require => Package["postfix-mysql"]
        }

        file { "/etc/postfix/mysql_virtual_domains_maps.cf":
                owner   => root,
                group   => root,
                mode    => 444,
                content => template('atomia/mailserver/mysql_virtual_domains_maps.cf.erb'),
                require => Package["postfix-mysql"]
        }

        file { "/etc/postfix/mysql_virtual_mailbox_maps.cf":
                owner   => root,
                group   => root,
                mode    => 444,
        content => template('atomia/mailserver/mysql_virtual_mailbox_maps.cf.erb'),
                require => Package["postfix-mysql"]
        }

        file { "/etc/postfix/mysql_virtual_transport.cf":
                owner   => root,
                group   => root,
                mode    => 444,
                content => template('atomia/mailserver/mysql_virtual_transport.cf.erb'),
                require => Package["postfix-mysql"]
        }

        file { "/etc/dovecot/dovecot-sql.conf":
                owner   => root,
                group   => root,
                mode    => 444,
                content => template('atomia/mailserver/dovecot-sql.conf.erb'),
                require => Package["dovecot-common"],
        }

        file { "/etc/dovecot/dovecot.conf":
                owner   => root,
                group   => root,
                mode    => 444,
                source  => "puppet:///modules/atomia/mailserver/dovecot.conf",
                require => Package["dovecot-common"],
        }

        file { "/usr/bin/vacation.pl":
                owner   => root,
                group   => virtual,
                mode    => 750,
                content => template('atomia/mailserver/vacation.pl'),
        }

        file { "/var/log/vacation.log":
                owner   => virtual,
                group   => virtual,
                mode    => 640,
                ensure  => present,
        }

        file { "/etc/mailname":
                owner => root,
                group => root,
                mode => 444,
                content => $hostname,
                ensure => present,
        }

        exec { "gen-key":
                command => "/usr/bin/openssl genrsa -out /etc/dovecot/ssl.key 2048; chown root:root /etc/dovecot/ssl.key; chmod 0700 /etc/dovecot/ssl.key",
                creates => "/etc/dovecot/ssl.key",
                provider => "shell"
        }

        exec { "gen-csr":
                command => "/usr/bin/openssl req -new -batch -key /etc/dovecot/ssl.key -out /etc/dovecot/ssl.csr",
                creates => "/etc/dovecot/ssl.csr",
        }

        exec { "gen-cert":
                command => "/usr/bin/openssl x509 -req -days 3650 -in /etc/dovecot/ssl.csr -signkey /etc/dovecot/ssl.key -out /etc/dovecot/ssl.crt",
                creates => "/etc/dovecot/ssl.crt",
        }

        service { postfix:
                        name => postfix,
                        enable => true,
                        ensure => running,
                        subscribe => [ Package["postfix-mysql"], File["/etc/postfix/main.cf"], File["/etc/postfix/master.cf"] ]
        }

        service { dovecot:
                        name => dovecot,
                        enable => true,
                        ensure => running,
                        subscribe => [ Package["dovecot-common"], File["/etc/dovecot/dovecot.conf"], File["/etc/dovecot/dovecot-sql.conf"] ]
        }

    group { "virtual":
        ensure => present
    }

    user { "virtual":
        ensure => present,
        comment => "virtual",
        groups => "virtual",
        membership => minimum,
        shell => "/bin/bash",
        require => Group["virtual"],
    }

}