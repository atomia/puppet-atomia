class atomia::atomiarepository {

  # Workaround for Debian Jessie
  if $::operatingsystem == 'Debian' {
    # Currently only supports Wheezy
    $repo = 'debian-wheezy wheezy main'
  }
  else {
    $repo = "ubuntu-${::lsbdistcodename} ${::lsbdistcodename} main"
  }

  if $::osfamily == 'RedHat' {
    if $::operatingsystemmajrelease == '7' {
      file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-ATOMIA':
        owner  => 'root',
        group  => 'root',
        mode   =>  '0644',
        source => 'puppet:///modules/atomia/repository/RPM-GPG-KEY-ATOMIA',
      }

      file { '/etc/yum.repos.d/atomia-rhel7.repo':
        owner   => 'root',
        group   => 'root',
        mode    =>  '0644',
        source  => 'puppet:///modules/atomia/repository/atomia-rhel7.repo',
        require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-ATOMIA'],
      }
    }
    else
    {
      exec { 'add rpm repo':
        command => '/usr/bin/rpm -Uhv http://rpm.atomia.com/rhel6/atomia-repository-setup-1.0-1.el6.noarch.rpm',
        unless  => "/usr/bin/rpm -qi atomia-repository-setup-1.0-1.el6.noarch | /bin/grep  -c 'Build Date'"
      }
    }
  }
  else {
    apt::key { 'puppet gpg key':
	    id     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
	    server => 'hkps.pool.sks-keyservers.net',
    }

    file { '/etc/apt/sources.list.d/atomia.list':
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      content => "deb http://apt.atomia.com/${repo}",
    }

    file { '/etc/apt/ATOMIA-GPG-KEY.pub':
      owner  => 'root',
      group  => 'root',
      mode   => '0440',
      source => 'puppet:///modules/atomia/repository/ATOMIA-GPG-KEY.pub'
    }

    exec { 'add keys':
      command     => '/usr/bin/apt-key add /etc/apt/ATOMIA-GPG-KEY.pub',
      onlyif      => ['/usr/bin/test -f /etc/apt/ATOMIA-GPG-KEY.pub'],
      subscribe   => File['/etc/apt/ATOMIA-GPG-KEY.pub'],
      refreshonly => true
    }

    file { '/etc/apt/apt.conf.d/80atomiaupdate':
      owner  => 'root',
      group  => 'root',
      mode   => '0440',
      source => 'puppet:///modules/atomia/repository/80atomiaupdate',
    }

    exec { 'apt-update':
      command => '/usr/bin/apt-get update',
      require => File['/etc/apt/apt.conf.d/80atomiaupdate', '/etc/apt/ATOMIA-GPG-KEY.pub', '/etc/apt/sources.list.d/atomia.list'],
      refreshonly => true
    }

    Exec['apt-update'] -> Package <| |>
  }

}
