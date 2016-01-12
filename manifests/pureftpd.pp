## Atomia PureFTPD resource server

### Deploys and configures a server running PureFTPD for hosting customer content.

### Variable documentation
#### agent_user: The username of the MySQL user that automation server provisions FTP users through.
#### agent_password: The password for the MySQL user that automation server provisions FTP users through.
#### master_ip: The IP of the master FTP server.
#### provisioning_host: The IP or hostname of the server running automation server, used for the automation server MySQL user to restrict access.
#### pureftpd_password: The password for the MySQL user with the name pureftpd that the FTP server connects to the user database as.
#### ftp_cluster_ip: The virtual IP of the FTP cluster.
#### content_share_nfs_location: The location of the NFS share for customer website content.
#### is_master: Toggles if we are provisioning the master FTP node (with the main user database) or a slave node (with a replicated database). 
#### pureftpd_slave_password: The password for the MySQL user with the name slave_user that the user database replication uses.
#### mysql_root_password: The password for the MySQL root user.
#### ssl_enabled: Toggles if we are to configure SSL for the FTP service.
#### skip_mount: Toggles if we are to mount the content share or not.
#### content_mount_point: The mount point for the customer content.
#### passive_port_range: The passive port range to use in the FTP server.

### Validations
##### agent_user(advanced): %username
##### agent_password(advanced): %password
##### master_ip(advanced): %ip
##### provisioning_host(advanced): ^[0-9.a-z%-]+$
##### pureftpd_password(advanced): %password
##### ftp_cluster_ip(advanced): %ip
##### content_share_nfs_location(advanced): %nfs_share
##### is_master(advanced): %int_boolean
##### pureftpd_slave_password(advanced): %password
##### mysql_root_password(advanced): %password
##### ssl_enabled(advanced): %int_boolean
##### skip_mount(advanced): %int_boolean
##### content_mount_point(advanced): %path
##### passive_port_range(advanced): ^[0-9]+ [0-9]+$

class atomia::pureftpd (
	$agent_user	 		= "automationserver",
	$agent_password,
	$master_ip			= $ipaddress,
	$provisioning_host		= "%",
	$pureftpd_password,
	$ftp_cluster_ip,
	$content_share_nfs_location	= ''
	$is_master			= 1,
	$pureftpd_slave_password,
	$mysql_root_password,
	$ssl_enabled			= 0,
	$skip_mount			= 0,
	$content_mount_point		= "/storage/content",
	$passive_port_range		= "49152 65534"
){

	package { pure-ftpd-mysql: ensure => installed }
	package { xinetd: ensure => installed }

	if $skip_mount == 0 {
				
		if $content_share_nfs_location == '' {
			$internal_zone = hiera('atomia::internaldns::zone_name','')
			package { 'glusterfs-client': ensure => present, }
			
			if !defined(File["/storage"]) {
				file { "/storage":
				ensure => directory,
				}
			}
			
			fstab::mount { '/storage/content':
				ensure  => 'mounted',
				device  => "gluster.${internal_zone}:/web_volume",
				options => 'defaults,_netdev',
				fstype  => 'glusterfs',
				require => [Package['glusterfs-client'],File["/storage"]],
			}			
    	}
		else
		{
			atomia::nfsmount { 'mount_content':
				use_nfs3		 => 1,
				mount_point  => '/storage/content',
				nfs_location => $content_share_nfs_location
			}
		}
	}

	if $is_master == "1" {
		class { 'mysql::server':
			restart			=> true,
			root_password		=> $mysql_root_password,
			remove_default_accounts	=> true,
			override_options => {
				mysqld => {
					'server_id'	=> '1',
					'log_bin'	=> '/var/log/mysql/mysql-bin.log',
					'binlog_do_db'	=> 'pureftpd',
					'bind_address'	=> $master_ip,
				}
			}
		}

		mysql_user { "create-automationserver-user":
			name		=> "$agent_user@$provisioning_host",
			ensure		=> 'present',
			password_hash	=> mysql_password($pureftpd_password),
			require		=> Class[Mysql::Server::Service],
		}

		mysql_grant { "$agent_user@$provisioning_host/pureftpd.*":
			ensure		=> 'present',
			options		=> ['GRANT'],
			privileges	=> ['INSERT', 'SELECT', 'UPDATE', 'DELETE'],
			table		=> 'pureftpd.*',
			user		=> "$agent_user@$provisioning_host",
			require		=> Mysql_database['create-pureftpd-database']
		}

		mysql_user { "create-slave-user":
			name		=> "slave_user@%",
			ensure		=> 'present',
			password_hash	=> mysql_password($pureftpd_slave_password),
			require		=> Class[Mysql::Server::Service],
		}

		mysql_grant { "slave_user@%/*.*":
			ensure		=> 'present',
			options		=> ['GRANT'],
			privileges	=> ['ALL', 'REPLICATION SLAVE'],
			table		=> '*.*',
			user		=> "slave_user@%",
			require		=> Class[Mysql::Server::Service],
		}


		exec { 'setup-master':
			command	=> "/etc/pure-ftpd/setup_database.sh master",
			require	=> [
				File["/etc/pure-ftpd/setup_database.sh"],
				Class[Mysql::Server::Service],
				File["/etc/pure-ftpd/mysql.schema.sql"],
				Mysql_database['create-pureftpd-database'],
				Mysql_grant["slave_user@%/*.*"]
			],
			unless	=> "/etc/pure-ftpd/setup_database.sh master_is_done",
		}

		file { "/etc/pure-ftpd/mysql.schema.sql":
			owner		=> root,
			group		=> root,
			mode		=> "400",
			source		=> "puppet:///modules/atomia/pureftpd/mysql.schema.sql",
			require 	=> Package["pure-ftpd-mysql"],
		}
	} else {
		# Slave config
		class { 'mysql::server':
			restart			=> true,
			root_password		=> $mysql_root_password,
			remove_default_accounts	=> true,
			override_options	=> {
				mysqld => {
					'server_id'	=> '2',
					'log_bin'	=> '/var/log/mysql/mysql-bin.log',
					'binlog_do_db'	=> 'pureftpd',
				}
			}
		}

		exec { 'setup-slave':
			command	=> "/etc/pure-ftpd/setup_database.sh slave",
			require	=> [
				File["/etc/pure-ftpd/setup_database.sh"],
				Class[Mysql::Server::Service],
				Mysql_database['create-pureftpd-database'],
				Mysql_grant['pureftpd@localhost/pureftpd.*'],
			],
			unless	=> "/etc/pure-ftpd/setup_database.sh slave_is_done",
		}
	}

	mysql_database { "create-pureftpd-database":
		name	=> "pureftpd",
		ensure	=> "present",
		require	=> Class[Mysql::Server::Service],
	}

	mysql_user { "create-pureftpd-user":
		name		=> "pureftpd@localhost",
		ensure		=> 'present',
		password_hash	=> mysql_password($pureftpd_password),
		require		=> Class[Mysql::Server::Service],
	}

	mysql_grant { "pureftpd@localhost/pureftpd.*":
		ensure		=> 'present',
		options		=> ['GRANT'],
		privileges	=> ['ALL'],
		table		=> 'pureftpd.*',
		user		=> "pureftpd@localhost",
		require		=> Mysql_database['create-pureftpd-database']
	}

	file { "/etc/pure-ftpd/setup_database.sh":
		owner		=> root,
		group		=> root,
		mode		=> "500",
		content		=> template("atomia/pure-ftpd/setup_database.sh.erb"),
		require		=> Package["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/db/mysql.conf":
		owner		=> root,
		group		=> root,
		mode		=> "400",
		content		=> template("atomia/pure-ftpd/mysqlsettings.cfg.erb"),
		require		=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/ChrootEveryone":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		content 	=> "yes",
		require 	=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/CreateHomeDir":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		content		=> "yes",
		require		=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/DontResolve":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		content 	=> "yes",
		require 	=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/MaxClientsNumber":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		content 	=> "150",
		require 	=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/DisplayDotFiles":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		content 	=> "yes",
		require 	=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/PassivePortRange":
		owner		=> root,
		group		=> root,
		mode		=> "444",
		content 	=> $passive_port_range,
		require 	=> Package["pure-ftpd-mysql"],
		notify		=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/LimitRecursion":
		owner	=> root,
		group	=> root,
		mode	=> "444",
		content	=> "15000 15",
		require	=> Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/ForcePassiveIP":
		owner	=> root,
		group	=> root,
		mode	=> "444",
		content	=> "$ftp_cluster_ip",
		require	=> Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

	service { pure-ftpd-mysql:
		name		=> pure-ftpd-mysql,
		pattern		=> "pure-ftpd.*",
		enable		=> true,
		ensure		=> running,
		subscribe	=> [
			Package["pure-ftpd-mysql"],
			File["/etc/pure-ftpd/db/mysql.conf"],
			File["/etc/pure-ftpd/conf/ChrootEveryone"],
			File["/etc/pure-ftpd/conf/CreateHomeDir"],
			File["/etc/pure-ftpd/conf/DontResolve"],
			File["/etc/pure-ftpd/conf/PassivePortRange"]
		],
	}

	if $ssl_enabled != 0 {
		file { "/etc/ssl":
			ensure	=> directory,
			owner	=> "root",
			group	=> "root",
			mode	=> "0600",
		}

		file { "/etc/ssl/private":
			ensure	=> directory,
			owner	=> "root",
			group	=> "root",
			mode	=> "0600",
		}

		file { "/etc/pure-ftpd/conf/TLS":
			owner	=> root,
			group	=> root,
			mode	=> "444",
			content	=> "1",
			require	=> Package["pure-ftpd-mysql"],
			notify	=> Service["pure-ftpd-mysql"],
		}
	}

	service { xinetd:
		name		=> xinetd,
		ensure		=> running,
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
		owner	=> nobody,
		group	=> root,
		mode	=> "744",
		source	=> "puppet:///modules/atomia/pureftpd/check_ftp_health"
	}

	file { "/etc/xinetd.d/check_ftp_health":
		owner	=> root,
		group	=> root,
		source	=> "puppet:///modules/atomia/pureftpd/check_ftp_health_xinetd",
		notify	=> Service["xinetd"],
		require	=> Package["xinetd"]
	}
}
