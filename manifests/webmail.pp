## Atomia Webmail server

### Deploys and configures a Roundcube webmail server.

### Variable documentation
#### cluster_ip: The virtual IP of the mail cluster.

### Validations
##### cluster_ip: %ip

class atomia::webmail (
  $cluster_ip                   = '',
) {

  class { 'apt': }

  class { 'roundcube':
    db_type     => 'pgsql',
    db_name     => 'roundcube',
    db_host     => 'localhost',
    db_username => 'roundcube',
    db_password => 'secret',
  }

}
