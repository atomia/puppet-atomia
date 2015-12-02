## Atomia Database

### Deploys and configures a PostgreSQL server to use as a backend database for Atomia

### Variable documentation
#### atomia_user: The username of the PostgreSQL user that Atomia uses to connecto to the database
#### atomia_password: The password for the PostgreSQL user that Atomia uses to connecto to the database

### Validations
##### atomia_user(advanced): ^[a-z0-9_-]+$
##### atomia_password(advanced): %password

class atomia::atomia_database (
	$atomia_user = "atomia",
	$atomia_password
	){

	class { 'postgresql::server':
		ip_mask_deny_postgres_user => '0.0.0.0/32',
		ip_mask_allow_all_users    => '0.0.0.0/0',
		listen_addresses           => '*',
		ipv4acls                   => ['host all all 0.0.0.0/0 md5']
	}

	postgresql::server::role { 'atomia_postgresql_provisioning_user':
		username => $atomia_user,
		password_hash => postgresql_password($atomia_user, $atomia_password),
		createdb => true,
		createrole => true,
		superuser => true
	}
}
