#
# == Class: atomia::service_files
#
# Deploys different service files such as parking, under construction websites
# should be deployed on a node which has access to the shared storage.
# Since these files are changed depending on environment the manifest expects
# all files to be in the atomia file share.
#
#
# === Examples
#
# class {'atomia::service_files':}

class atomia::service_files (
) {
  exec {'check_presence_public_html':
    command => '/bin/true',
    onlyif  => '/usr/bin/test -d /storage/content/systemservices/public_html',
  }

  exec {'check_presence_100000':
    command => '/bin/true',
    onlyif  => '/usr/bin/test -d /storage/content/00/100000',
  }

  exec {'check_presence_00':
    command => '/bin/true',
    onlyif  => '/usr/bin/test -d /storage/content/00',
  }

  file { '/storage/content/00/100000':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0710',
    require => Exec['check_presence_00'],
  }

  file { '/storage/content/systemservices/public_html/forward.php':
    source => 'puppet:///modules/atomia/service_files/forward.php',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { '/storage/content/systemservices/public_html/index.php':
    source => 'puppet:///modules/atomia/service_files/index.php',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { '/storage/content/systemservices/public_html/suspend.php':
    source => 'puppet:///modules/atomia/service_files/suspend.php',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { '/storage/content/systemservices/public_html/nostats.html':
    source => 'puppet:///modules/atomia/service_files/nostats.html',
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
  }

  # Under construction
  file { '/storage/content/00/100000/index.html.default':
    source => 'puppet:///modules/atomia/service_files/index.html.default',
    mode   => '0644',
    owner  => 100000,
    group  => 100000,
  }

}
