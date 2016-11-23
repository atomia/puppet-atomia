## Cron agent

### Deploys and configures a server running the Atomia cron agent.

### Variable documentation
#### global_auth_token: The authentication token clients will use to access the API of the cron agent.
#### min_part: The lower part of the cron task cluster distribution range (0-1000) that this server handles.
#### max_part: The upper part of the cron task cluster distribution range (0-1000) that this server handles.
#### mail_host: The hostname or IP of the SMTP server to send mails through.
#### mail_port: The port of the SMTP server to send mails through.
#### mail_user: The username to authenticate as when connecting to the SMTP server used for sending mails.
#### mail_pass: The password to authenticate with when connecting to the SMTP server used for sending mails.
#### mail_from: The sender email to set for the mails sent by the cron service.
#### base_url: The base URL for the cron agent API.
#### mail_ssl: Use SSL for email
#### mongo_admin_user: The admin username for the MongoDB.
#### mongo_admin_pass: The admin password for the MongoDB.
#### mongo_cron_user: The username that the cronagent will use to connect to MongoDB.
#### mongo_cron_pass: The password that the cronagent will use to connect to MongoDB.
#### mongo_db_name: The database name that the cronagent will use.

### Validations
##### mail_from: %email
##### global_auth_token(advanced): %password
##### min_part(advanced): ^([0-9]{1,3}|1000)$
##### max_part(advanced): ^([0-9]{1,3}|1000)$
##### mail_host(advanced): %hostname
##### mail_port(advanced): ^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$
##### mail_user(advanced): ^[^[[:space:]]]+$
##### mail_pass(advanced): .*
##### base_url(advanced): %url
##### mail_ssl(advanced): [0-1]
##### mongo_admin_user(advanced): ^[^[[:space:]]]+$
##### mongo_admin_pass(advanced): %password
##### mongo_cron_user(advanced): ^[^[[:space:]]]+$
##### mongo_cron_pass(advanced): %password
##### mongo_db_name(advanced): .*

class atomia::cronagent (
  $global_auth_token,
  $min_part           = 0,
  $max_part           = 1000,
  $mail_host          = 'localhost',
  $mail_port          = 25,
  $mail_ssl           = 0,
  $mail_from          = '',
  $mail_user          = '',
  $mail_pass          = '',
  $base_url           = "http://${::fqdn}:10101",
  $mongo_admin_user   = 'admin',
  $mongo_admin_pass   = '',
  $mongo_cron_user    = 'cronagent',
  $mongo_cron_pass    = '',
  $mongo_db_name      = 'cronagent'
){
  class {'::mongodb::globals':
    manage_package_repo => true
  } ->
  class {'::mongodb::client': } ->
  class {'::mongodb::server':
    auth           => true,
    create_admin   => true,
    store_creds    => true,
    admin_username => $mongo_admin_user,
    admin_password => $mongo_admin_pass,
  }

  package { 'atomia-cronagent':
    ensure  => present,
    require => Class['mongodb::server']
  }

  file { '/etc/default/cronagent':
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template('atomia/cronagent/settings.cfg.erb'),
    require => Package['atomia-cronagent'],
  }

  service { 'atomia-cronagent':
    ensure    => running,
    enable    => true,
    hasstatus => false,
    pattern   => '/usr/bin/(atomia-)?cronagent',
    require   => [ Package['atomia-cronagent'], File['/etc/default/cronagent'] ],
    subscribe => File['/etc/default/cronagent'],
  }

  mongodb_user { $mongo_cron_user:
    name          => $mongo_cron_user,
    password_hash => mongodb_password($mongo_cron_user, $mongo_cron_pass),
    ensure        => present,
    database      => $mongo_db_name,
    roles         => [ 'readWrite', 'dbAdmin' ],
    require       => Package['atomia-cronagent']
  }

  if $mail_host == 'localhost' or $mail_host == '127.0.0.1' {
    package { 'postfix' :
      ensure => present,
    }
  }

}
