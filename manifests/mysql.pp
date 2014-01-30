#$mysql_command = "mysql --defaults-file=/etc/mysql/debian.cnf -Ns"
#define mysql_database($name, $schema_table, $initial_schema) {
#	exec { "create-db $name":
#		command => "$mysql_command -e 'CREATE DATABASE $name'",
#		unless => "/usr/bin/test -d $mysql_datadir/$name",
#	}
#
#	exec { "import-schema $name":
#		command => "$mysql_command $name < $initial_schema",
#		unless => "$mysql_command -e \"SELECT * FROM $schema_table\" $name",
#	}
#}

#define mysql_user($name, $host, $db_grant, $password, $grant_option) {
#	case $grant_option {
#		true: { $grant_statement = " WITH GRANT OPTION" }
#		default: { $grant_statement = "" }
#	}
#
#	exec { $name:
#		command => "$mysql_command -e \"GRANT ALL ON $db_grant.* TO '$name'@'$host' IDENTIFIED BY '$password'$grant_statement\"",
#		unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$name' AND host = '$host'\" mysql | grep $name",
#	}
#}

class atomia::mysql (
	$mysql_username,
	$mysql_password,
	$provisioning_host
	){
	$mysql_datadir = "/var/lib/mysql/data"
	$mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"

	#package { mysql-server: ensure => installed }

	package { apache2: ensure => present }
	package { libapache2-mod-php5: ensure => present }

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
       
	 service { apache2:
                name => apache2,
                enable => true,
                ensure => running,
        }

	exec { "delete-test-db":
		command => "$mysql_command -e \"DROP DATABASE test;\" ",
		onlyif => "$mysql_command -e \"SHOW DATABASES;\" | grep test"
	}

	file { "/etc/cron.hourly/ubuntu-mysql-fix":
                owner   => root,
                group   => root,
                mode    => 500,
                source  => "puppet:///modules/atomia_mysql/ubuntu-fix",
	}

	file { "/etc/security/limits.conf":
		   owner   => root,
		   group   => root,
		   mode    => 644,
		   source  => "puppet:///modules/atomia_mysql/limits.conf",
	}


#	file { "/etc/mysql/my.cnf":
#		   owner   => root,
#		   group   => root,
#		   mode    => 644,
#		   source  => "puppet:///modules/mysql/my.cnf",
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

