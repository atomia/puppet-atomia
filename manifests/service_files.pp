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
    
  file { '/storage/content/systemservices/public_html/forward.php':
  	source		=> "puppet:///atomia/service_files/forward.php",
    mode    => 0755,
    owner   => root,
    group   => root,
  }

  file { '/storage/content/systemservices/public_html/index.php':
    source    => "puppet:///atomia/service_files/index.php",
    mode    => 0755,
    owner   => root,
    group   => root,
  }

  file { '/storage/content/systemservices/public_html/suspend.php':
    source    => "puppet:///atomia/service_files/suspend.php",
    mode    => 0755,
    owner   => root,
    group   => root,
  }

  file { '/storage/content/systemservices/public_html/nostats.html':
    source    => "puppet:///atomia/service_files/nostats.html",
    mode    => 0444,
    owner   => root,
    group   => root,
  }

  # Under construction
  file { '/storage/content/00/100000/index.html.default':
    source    => "puppet:///atomia/service_files/index.html.default",
    mode    => 0644,
    owner   => 100000,
    group   => 100000,
  }

}
