## Atomia Database

### Deploys and configures a PostgreSQL server to use as a backend database for Atomia

### Variable documentation
#### atomia_user: The username of the PostgreSQL user that Atomia uses to connect to the database
#### atomia_password: The password for the PostgreSQL user that Atomia uses to connect to the database
#### server_address: The fqdn or ip address of the server
#### enable_backups: If enabled will create a backup schedule of the PostgreSQL databases
#### backup_dir: The directory to place the PostgreSQL backups in
#### cron_schedule_hour: At what hour of the day should the backup be run. 1 means 1AM.

### Validations
##### atomia_user(advanced): ^[a-z0-9_-]+$
##### atomia_password(advanced): %password
##### enable_backups(advanced): %int_boolean
##### backup_dir(advanced): .*
##### cron_schedule_hour(advanced): ^[0-9]{1,2}$

class atomia::atomia_database (
  $atomia_user      = 'atomia',
  $atomia_password,
  $enable_backups     = '1',
  $server_address     = $fqdn,
  $backup_dir         = '/opt/atomia_backups',
  $cron_schedule_hour = '1'
){

  package { 'postgresql-contrib':
    ensure  => present
  }

  class { 'postgresql::server':
    ip_mask_allow_all_users => '0.0.0.0/0',
    listen_addresses        => '*',
    ipv4acls                => ['host all atomia 0.0.0.0/0 md5']
  }

  postgresql::server::role { 'atomia_postgresql_provisioning_user':
    username      => $atomia_user,
    password_hash => postgresql_password($atomia_user, $atomia_password),
    createdb      => true,
    createrole    => true,
    superuser     => true
  }

  postgresql::server::pg_hba_rule { 'allow network acces for atomia user':
    description => 'Open up postgresql for access for Atomia user',
    type        => 'host',
    database    => 'all',
    user        => $atomia_user,
    address     => '0.0.0.0/0',
    auth_method => 'password',
    notify      => Service['postgresql']
  }
  if($enable_backups == '1' and !defined(Class['atomia::postgresql_backup'])) {
    class {'atomia::postgresql_backup':
      backup_dir         => $backup_dir,
      cron_schedule_hour => $cron_schedule_hour,
      backup_user        => $atomia_user,
      backup_password    => $atomia_password
    }
  }
}
