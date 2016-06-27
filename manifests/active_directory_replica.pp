## Atomia Active Directory

### Deploys and configures a replica for Active Directory

### Variable documentation
#### replica_ip: The ip address of this server

### Validations
##### replica_ip(advanced): .*

class atomia::active_directory_replica (
  $replica_ip             = $::ipaddress,
) {

    $domain_name = hiera(atomia::active_directory::domain_name)
    $netbios_domain_name = hiera(atomia::active_directory::netbios_domain_name)
    $restore_password = hiera(atomia::active_directory::restore_password)
    $app_password = hiera(atomia::active_directory::app_password)
    $bind_password = hiera(atomia::active_directory::bind_password)
    $windows_admin_password = hiera(atomia::active_directory::windows_admin_password)


    File { source_permissions => ignore }

    if !defined(File['c:/install']) {
        file { 'c:/install':
            ensure => 'directory',
        }
    }

    file { 'c:/install/sync_time.ps1':
        ensure  => 'file',
        content => template('atomia/active_directory/sync_time.ps1.erb'),
        require => File['c:/install'],
    }

    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role_ad.ps1':
        content => template('atomia/active_directory/atomia_role_active_directory_replica.ps1.erb'),
    }

    file {'c:/install/update_dns.ps1':
        ensure => file,
        source => 'puppet:///modules/atomia/active_directory/update_dns.ps1',
    }

    $active_directory_ip = hiera('atomia::active_directory::master_ip','')
    exec { 'set-dns':
        command => "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -executionpolicy remotesigned -file c:/install/update_dns.ps1 ${active_directory_ip}",
        require => File['c:/install/update_dns.ps1'],
    }
    ->
    exec { 'enable-ad-feature':
        command  => 'Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools',
        onlyif   => 'Import-Module ServerManager; if ((Get-WindowsFeature Ad-Domain-Service).Installed) { exit 1 } else { exit 0 }',
        provider => powershell,
    }

    exec { 'Install AD replica':
        command  => template('atomia/active_directory/ad-replica.ps1.erb'),
        unless   => "if((gwmi WIN32_ComputerSystem).Domain -ne \"${domain_name}\") { exit 1 }",
        require  => Exec['enable-ad-feature'],
        provider => powershell,
    }

    exec { 'sync-time':
        command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/sync_time.ps1',
        require => File['c:/install/sync_time.ps1'],
    }
}