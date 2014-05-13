class atomia::mailserver_forwarder (
                $provisioning_host,
                $is_master = 0,
                $master_ip,
                $agent_password,
                $slave_password,
                $cluster_ip = ""
        ){
        package { postfix-mysql: ensure => installed }
       
        $db_hosts = $ipaddress
        $db_user = "vmail"
        $db_user_smtp = "smtp_vmail"
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



        file { "/etc/mailname":
                owner => root,
                group => root,
                mode => 444,
                content => $hostname,
                ensure => present,
        }


        service { postfix:
                        name => postfix,
                        enable => true,
                        ensure => running,
                        subscribe => [ Package["postfix-mysql"], File["/etc/postfix/main.cf"], File["/etc/postfix/master.cf"] ]
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
