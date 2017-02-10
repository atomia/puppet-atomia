## Atomia public_apps

### Deploys and configures Atomia Public Apps

### Variable documentation
#### repository: The repository name to install the application from

### Validations
##### repository(advanced): ^(PublicRepository|TestRepository)+


class atomia::public_apps (
  $repository = 'PublicRepository',){

    # Set ip correctly when on ec2
    if !$public_ip {
      if $::ec2_public_ipv4 {
        $public_ip = $::ec2_public_ipv4
      } elsif $::ipaddress_eth0 {
        $public_ip = $::ipaddress_eth0
      }
      else {
        $public_ip = $::ipaddress
      }
    }
    File { source_permissions => ignore }


    if($repository == 'PublicRepository')
    {
      exec {'install-identity':
        command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository PublicRepository -application "Atomia Identity WF2"',
        require => [Exec['install-setuptools'],File['unattended.ini']],
        creates => 'C:\Program Files (x86)\Atomia\Identity',
      }
    ->
    exec {'install-hcp':
      command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository PublicRepository -application "Atomia Hosting Control Panel"',
      require => [Exec['install-identity'],File['unattended.ini']],
      creates => 'C:\Program Files (x86)\Atomia\HostingControlPanel',
    }
  ->
  exec {'install-bcp':
    command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository PublicRepository -application "Atomia Billing Customer Panel"',
    require => [Exec['install-identity'],File['unattended.ini']],
    creates => 'C:\Program Files (x86)\Atomia\BillingCustomerPanel',
  }
  ->
  exec {'install-store':
    command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository PublicRepository -application "Atomia Store"',
    require => [Exec['install-identity'],File['unattended.ini']],
    creates => 'C:\Program Files (x86)\Atomia\Store',
    notify  => Exec['app-pool-settings']
  }

  }
  else
  {
    exec {'install-identity':
      command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository TestRepository -application "Atomia Identity WF2"',
      require => [Exec['install-setuptools'],File['unattended.ini']],
      creates => 'C:\Program Files (x86)\Atomia\Identity',
    }
  ->
  exec {'install-hcp':
    command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository TestRepository -application "Atomia Hosting Control Panel"',
    require => [Exec['install-identity'],File['unattended.ini']],
    creates => 'C:\Program Files (x86)\Atomia\HostingControlPanel',
  }
->
exec {'install-bcp':
  command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository TestRepository -application "Atomia Billing Customer Panel"',
  require => [Exec['install-identity'],File['unattended.ini']],
  creates => 'C:\Program Files (x86)\Atomia\BillingCustomerPanel',
}
->
  exec {'install-store':
    command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository TestRepository -application "Atomia Store"',
    require => [Exec['install-identity'],File['unattended.ini']],
    creates => 'C:\Program Files (x86)\Atomia\Store',
    notify  => Exec['app-pool-settings']
  }
  }

  if(!defined(File['c:/install/app-pool-settings.ps1'])) {
    file { 'c:/install/app-pool-settings.ps1':
      ensure => 'file',
      source => 'puppet:///modules/atomia/windows_base/app-pool-settings.ps1'
    }
  }

  if(!defined(Exec['app-pool-settings']) and $::atomia_role_1 != 'test_environment') {
    exec { 'app-pool-settings':
      command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/app-pool-settings.ps1',
      require => File['c:/install/app-pool-settings.ps1'],
      refreshonly => true
    }
  }

  if ($::atomia_role_1 != 'test_environment') {
    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_public.txt':
      content => 'atomia_role_1=atomia_public_apps',
    }
  }
  }
