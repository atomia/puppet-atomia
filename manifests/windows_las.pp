class atomia::windows_las () 

  {

    # Deploy install folder if not exist
    file { 'c:/install': 
        ensure => 'directory',
        creates => 'c:\install',
    }

    file { 'c:/install/ntrights.exe':
        ensure => 'file',
        source => "puppet:///modules/atomia/ntrights.exe"
    }

    exec { 'grand_logon_as_service':
        command => 'cmd.exe /c "C:\install\ntrights +r SeServiceLogonRight -u "ATOMIA\apppooluser"',
        require => File["c:/install/ntrights.exe"]
      }
}
