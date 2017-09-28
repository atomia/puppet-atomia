## Atomia Internal_mailserver

### Deploys a postfix mailserver used for sending mail from the Atomia platform

### Variable documentation
#### allow_subnet: The subnet to allow sending email

### Validations
##### allow_subnet: .*


class atomia::internal_mailserver (
  $allow_subnet = '10.0.0.0/24',
){
  package { 'postfix': ensure => present }

  # Modify configuration with Augeas

  augeas { 'postfix-main-cf':
    context => '/files/etc/postfix/main.cf',
    changes => [
      "set mynetworks ${allow_subnet}",
    ],
    require => [ Package['postfix'] ],
    notify  => Service['postfix']
  }

  service { 'postfix':
    ensure  => running
  }
}
