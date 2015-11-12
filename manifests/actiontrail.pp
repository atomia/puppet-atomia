## Atomia Actiontrail

### Deploys and configures Active Directory

### Variable documentation
#### repository: The repository name to install the application from

### Validations
##### repository(advanced): ^(PublicRepository|TestRepository)+


class atomia::actiontrail (
  $repository = "PublicRepository",){

  # Set ip correctly when on ec2
  if $ec2_public_ipv4 {
    $public_ip = $ec2_public_ipv4
  } else {
    $public_ip = $ipaddress_eth0
  }

	atomia::actiontrail::register{ "${::fqdn}": content => $public_ip}

	exec { 'install-actiontrail':
		command   => "c:/install/install_atomia.ps1  -repository ${repository} -application 'Atomia ActionTrail'",
		require   => [Exec['install-setuptools'],File['unattended.ini']],
		provider  => powershell,
	}
}


define atomia::actiontrail::register ($content="") {
  $factfile = 'C:\ProgramData\PuppetLabs\facter\facts.d\actiontrail_ip.txt'

  @@concat::fragment {"actiontrail_ip_${content}":
      target => $factfile,
      content => "${content}",
      tag => 'actiontrail_ip',
      order => 1
    }

}
