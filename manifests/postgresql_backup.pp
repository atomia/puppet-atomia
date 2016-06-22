class atomia::postgresql_backup (
    $backup_dir         = '/opt/atomia_backups',
    $cron_schedule_hour = '1',
    $backup_user,
    $backup_password,
) {

    package { 'cron':
        ensure => present
    }

    file { '/opt/postgresql_backup':
        ensure  => directory,
    }

    file { '/opt/atomia_backups':
        ensure  => directory,
        owner   => 'postgres',
        require => Package['postgresql-contrib']
    }

    file { '/var/lib/postgresql/.pgpass':
        mode    => '0600',
        content => "localhost:5432:*:${backup_user}:${backup_password}",
        owner   => 'postgres',
        require => Package['postgresql-contrib']
    }

    file { '/opt/postgresql_backup/pg_backup_rotated.sh':
        ensure  => present,
        source  => 'puppet:///modules/atomia/postgresql/pg_backup_rotated.sh',
        require => [Package['postgresql-contrib'], File['/opt/postgresql_backup']],
        mode    => '0755',
        owner   => 'postgres'
    }

    file { '/opt/postgresql_backup/pg_backup.config':
        ensure  => present,
        content => template('atomia/postgresql/pg_backup.config.erb'),
        require => [Package['postgresql-contrib'], File['/opt/postgresql_backup']],
        owner   => 'postgres'
    }

    cron { 'atomia_database_backup':
        command => '/opt/postgresql_backup/pg_backup_rotated.sh',
        user    => 'postgres',
        hour    => $cron_schedule_hour,
        minute  => 0,
        require => [Package['postgresql-contrib'], Package['cron']]

    }

}