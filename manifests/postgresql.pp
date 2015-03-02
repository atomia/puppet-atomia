class atomia::postgresql (
	$postgresql_username,
	$postgresql_password,
	$provisioning_host
	){

	class { 'postgresql::server':
		ip_mask_deny_postgres_user => '0.0.0.0/32',
		ip_mask_allow_all_users    => '0.0.0.0/0',
		listen_addresses           => '*',
		ipv4acls                   => ['host all all 0.0.0.0/0 md5']
	}

	postgresql::server::role { 'atomia_postgresql_provisioning_user':
		username => $postgresql_username,
		password_hash => postgresql_password($postgresql_username, $postgresql_password),
		createdb => true,
		createrole => true,
		superuser => true
	}
}
