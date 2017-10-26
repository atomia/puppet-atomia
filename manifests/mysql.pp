## Atomia customer MySQL resource server

### Deploys and configures a server running MySQL for hosting customer databases.

### Variable documentation
#### mysql_username: The username of the MySQL user that automation server provisions databases through.
#### mysql_password: The password for the MySQL user that automation server provisions databases through.
#### mysql_root_password: The password for the MySQL root user.
#### provisioning_host: The IP or hostname of the server running automation server, used for the automation server MySQL user to restrict access.
#### server_ip: Mysql server management IP address
#### server_public_ip: Mysql server public IP address

### Validations
##### mysql_username(advanced): %username
##### mysql_password(advanced): %password
##### mysql_root_password(advanced): %password
##### provisioning_host(advanced): ^[0-9.a-z%-]+$
##### server_ip: .*
##### server_public_ip: .*

class atomia::mysql (
  $mysql_username       = 'automationserver',
  $mysql_password,
  $mysql_root_password,
  $provisioning_host    = '%',
  $server_ip            = '',
  $server_public_ip     = '',
){

  # TODO: Consider changing % to hostname for automation server in internal zone when this is setup.

  class { '::mysql::server':
    restart                 => true,
    root_password           => $mysql_root_password,
    remove_default_accounts => true,
    override_options        => {
    'mysqld' => {
      'bind_address' => '*',
      'skip-name-resolve' => '',
      }
    }
  }

  mysql_user { "${mysql_username}@${provisioning_host}":
    ensure        => 'present',
    password_hash => mysql_password($mysql_password),
  }

  mysql_grant { "${mysql_username}@${provisioning_host}/*.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => '*.*',
    user       => "${mysql_username}@${provisioning_host}",
  }

  limits::conf { 'soft-file-limit':
    domain => '*',
    type   => 'soft',
    item   => 'nofile',
    value  => 65535
  }

  limits::conf { 'hard-file-limit':
    domain => '*',
    type   => 'hard',
    item   => 'nofile',
    value  => 65535
  }
}
