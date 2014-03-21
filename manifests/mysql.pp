class atomia::mysql (
	$mysql_username,
	$mysql_password,
	$provisioning_host
	){
	$mysql_datadir = "/var/lib/mysql/data"
	$mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"

	#package { mysql-server: ensure => installed }


	class { '::mysql::server':
  		override_options => { 'mysqld' => { 'bind_address' => $ipaddress } }
	}	

	mysql_user { "$mysql_username@$provisioning_host":
 		ensure          => 'present',
		password_hash	=> mysql_password($mysql_password),
	}

	mysql_grant { "$mysql_username/*.*":
  		ensure     => 'present',
  		options    => ['GRANT'],
  		privileges => ['ALL'],
  		table      => '*.*',
  		user       => "$mysql_username@$provisioning_host",
	}
       

	exec { "delete-test-db":
		command => "$mysql_command -e \"DROP DATABASE test;\" ",
		onlyif => "$mysql_command -e \"SHOW DATABASES;\" | grep test"
	}

	file { "/etc/cron.hourly/ubuntu-mysql-fix":
                owner   => root,
                group   => root,
                mode    => 500,
                source  => "puppet:///modules/atomia/mysql/ubuntu-fix",
	}

	file { "/etc/security/limits.conf":
		   owner   => root,
		   group   => root,
		   mode    => 644,
		   source  => "puppet:///modules/atomia/mysql/limits.conf",
	}


#	file { "/etc/mysql/my.cnf":
#		   owner   => root,
#		   group   => root,
#		   mode    => 644,
#		   source  => "puppet:///modules/atomia/mysql/my.cnf",
#	}
	
#	if !defined(File[$mysql_datadir]) {
#		file { $mysql_datadir:
#			  ensure => directory,
#			  owner => "mysql",
#			  group => "mysql",
#			  require => Package["mysql-server"],
#		}
#	}
}

