## Atomia Domain Registration

### Deploys and configures a server running Atomia Domain Registration.

### Variable documentation
#### service_url: The URL of the Atomia Domain Registration service.
#### service_username: The username to require for accessing the service.
#### service_password: The password to require for accessing the service.
#### db_hostname: The hostname of the Atomia Domain Registration database.
#### db_username: The username for the Atomia Domain Registration database.
#### db_password: The password for the Atomia Domain Registration database.
#### domainreg_global_config: The global section of the /etc/domainreg.conf file.
#### domainreg_tld_config_hash: The TLD configuration sections for all the Atomia Domain Registration TLD processes.
#### enable_backups: If enabled will create a backup schedule of the PostgreSQL databases
#### backup_dir: The directory to place the PostgreSQL backups in
#### cron_schedule_hour: At what hour of the day should the backup be run. 1 means 1AM.

### Validations
##### service_url(advanced): %url
##### service_username(advanced): %username
##### service_password(advanced): %password
##### db_hostname(advanced): %hostname
##### db_username(advanced): %username
##### db_password(advanced): %password
##### domainreg_global_config(advanced,default_file=domainreg_global_default.conf): %domainreg_global_config
##### domainreg_tld_config_hash: %domainreg_tld_config_hash
##### enable_backups(advanced): %int_boolean
##### backup_dir(advanced): .*
##### cron_schedule_hour(advanced): ^[0-9]{1,2}$

class atomia::domainreg (
  $service_url               = "http://${::fqdn}/domainreg",
  $service_username          = 'domainreg',
  $service_password          = '',
  $db_hostname               = '127.0.0.1',
  $db_username               = 'domainreg',
  $db_password               = '',
  $domainreg_global_config   = '',
  $domainreg_tld_config_hash = {},
  $enable_backups          = '1',
  $backup_dir              = '/opt/atomia_backups',
  $cron_schedule_hour      = '1'
){

  # Support both hash and Json format for domainreg_tld_config_hash
  if(!is_hash($domainreg_tld_config_hash)) {
    $config_hash = parsejson($domainreg_tld_config_hash)
  }
  else {
    $config_hash = $domainreg_tld_config_hash
  }
  $domainreg_global_config_default = file('atomia/domainreg/domainreg_global_default.conf')

  package { 'atomiadomainregistration-masterserver':
    ensure  => present,
    require => [ File['/etc/domainreg.conf'] ]
  }

  package { 'atomiadomainregistration-client': ensure => present }

  package { 'procmail': ensure => present }


  file { '/etc/domainreg.conf':
    path    => '/etc/domainreg.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('atomia/domainreg/domainreg.conf'),
    notify  => [ Service['atomiadomainregistration-api'], Service['apache2'] ]
  }

  service { 'atomiadomainregistration-api':
    ensure  => running,
    enable  => true,
    pattern => '.*/usr/bin/domainregistration.*',
    require => [ Package['atomiadomainregistration-masterserver'], Package['atomiadomainregistration-client'], File['/etc/domainreg.conf'] ],
  }

  if !defined(Class['atomia::apache_password_protect']) {
    class { 'atomia::apache_password_protect':
      username => $service_username,
      password => $service_password,
      require  => Package['atomiadomainregistration-masterserver'],
    }
  }

  service { 'apache2':
    ensure  => running,
    enable  => true,
    require => Package['atomiadomainregistration-masterserver'],
  }

  file { '/etc/cron.d/rotate-domainreg-logs':
    ensure  => present,
    content => "0 0 * * * root lockfile -r0 /var/run/rotate-domainreg-logs && (find /var/log/atomiadomainregistration -mtime +14 -exec rm -f '{}' '+'; rm -f /var/run/rotate-domainreg-logs.lock)",
  }

  package { 'postgresql-contrib':
    ensure  => present
  }
  if($enable_backups == '1' and !defined(Class['atomia::postgresql_backup'])) {
    class {'atomia::postgresql_backup':
      backup_dir         => $backup_dir,
      cron_schedule_hour => $cron_schedule_hour,
      backup_user        => $db_username,
      backup_password    => $db_password
    }
  }
}
