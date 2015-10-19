
class atomia::windows_base (
  $app_password,
  $ad_domain,
  $database_server,
  $mirror_database_server            = "",
  $appdomain,
  $actiontrail      = "actiontrail",
  $login            = "login",
  $order            = "order",
  $store	    = "store",
  $billing          = "billing",
  $admin            = "admin",
  $hcp              = "hcp",
  $automationserver = "automationserver",
  $automationserver_encryption_cert_thumb,
  $billing_encryption_cert_thumb,
  $billing_plugin_config             = "",
  $send_invoice_email_subject_format = "",
  $domainreg_service_url,
  $domainreg_service_username,
  $domainreg_service_password,
  $actiontrail_ip,
  $root_cert_thumb,
  $signing_cert_thumb,
  $mail_sender_address               = "",
  $mail_server_host = "",
  $mail_server_port = "25",
  $mail_server_username              = "",
  $mail_server_password              = "",
  $mail_server_use_ssl               = "false",
  $mail_bcc_list    = "",
  $mail_reply_to    = "",
  $sms_url    = "",
  $sms_server_username    = "",
  $sms_server_password    = "",
  $sms_originatortype     = "",
  $sms_originator         = "",
  $storage_server_hostname,
  $mail_dispatcher_interval         = "30",
  $is_iis             = 0) 

  {
  if( $is_iis == 0 ){
    
	  dism { 'NetFx3':
	  	ensure 	=> present,
		all	=> true,
	  }
	
	  # 6.1 is 2008 R2, so this matches 2012 and forward
	  # see http://msdn.microsoft.com/en-us/library/windows/desktop/ms724832(v=vs.85).aspx
	  if versioncmp($kernelmajversion, "6.1") > 0 {
	    dism { 'NetFx4Extended-ASPNET45':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'IIS-NetFxExtensibility45':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'IIS-ASPNET45':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'MSMQ-Services':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'MSMQ':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'windows-identity-foundation':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'WCF-HTTP-Activation':
	      ensure => present,
	      all    => true,
	    }
	
	    dism { 'WCF-HTTP-Activation45':
	      ensure => present,
	      all    => true,
	    }
	
	    file { 'c:/install/app-pool-settings.ps1':
	        ensure => 'file',
	        source => "puppet:///modules/atomia/windows_base/app-pool-settings.ps1"
	    }
	    
	    exec { 'app-pool-settings':
	        command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/app-pool-settings.ps1',
	        require => File["c:/install/app-pool-settings.ps1"]
	      }
	    
	  }
	
	  dism { 'MSMQ-Server':
	      ensure => present,
	      all    => true,
	    }
	
	  # Install IIS and modules
	  dism { 'IIS-WebServerRole':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-ISAPIFilter':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-ISAPIExtensions':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-NetFxExtensibility':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-ASPNET':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-CommonHttpFeatures':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-StaticContent':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-DefaultDocument':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-ManagementConsole':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-ManagementService':
	      ensure => present,
	      all    => true,
	    }
	
	  dism { 'IIS-HttpRedirect':
	      ensure => present,
	      all    => true,
	    }
  }
  # End IIS and modules

  file { 'c:/install': ensure => 'directory' }

  file { 'c:/install/base.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/baseinstall.ps"
  }

  file { 'c:/install/disableweakssl.reg':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/disableweakssl.reg"
  }

  file { 'c:/install/Windows6.1-KB2554746-x64.msu':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/Windows6.1-KB2554746-x64.msu"
  }
  
  
  # Install Packages with Chocolatey
  exec { 'install-chocolatey':
    command => "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))",
    provider  => powershell,
    onlyif  => 'Test-Path C:\ProgramData\Chocolatey'
  }
  
  exec { 'set-chocolatey-path':
    command => 'c:\windows\system32\cmd.exe /c SET PATH=%PATH%;%systemdrive%\ProgramData\chocolatey\bin',
    creates => "c:/install/chocolatey_installed.txt",
    require  => Exec['install-chocolatey'],
  }
  
  package { 'GoogleChrome': 
    ensure  => installed,
    provider  => 'chocolatey',
    require  => Exec['set-chocolatey-path'],
  }  
  
  package { 'notepadplusplus': 
    ensure  => installed,
    provider  => 'chocolatey',
    require  => Exec['set-chocolatey-path'],
  }  

  package { 'vcredist2008': 
    ensure  => installed,
    provider  => 'chocolatey',
    require  => Exec['set-chocolatey-path'],
  }  
  
  if versioncmp($kernelmajversion, "6.1") == 0 {
    # Install .net40 
	  file { 'c:/install/install_net40.ps1':
	    ensure => 'file',
	    source => "puppet:///modules/atomia/windows_base/install_net40.ps1",
	  }
	      
	  exec { 'Install-NET40':
	    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\install_net40.ps1',
	    creates => 'C:\install\installed_net40.txt',
      require => File['c:/install/install_net40.ps1'],
	  }    
  }
  
  # Install certificates
  file { 'C:\install\install_certificates.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/install_certificates.ps1",
    require => File['c:/install/certificates'],
  }
  exec { 'install-certificates':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\install_certificates.ps1',
    creates => 'C:\install\install_certificates.txt',
    require => File['C:\install\install_certificates.ps1'],
    }  
  
  # Install Atomia Installer
  file { 'C:\install\install_atomia_installer.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/install_atomia_installer.ps1",
  }

  exec { 'install-atomia-installer':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\install_atomia_installer.ps1',
    creates => 'C:\install\install_atomia_installer.txt',
  }    

  file { 'C:\ProgramData\Atomia Installer\appupdater.ini':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/appupdater.ini",
    require => Exec['install-atomia-installer']
  }  
  
  # Install other requirements
  exec { 'base-install':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\base.ps1',
    creates => 'C:\install\install_base.txt',
  }  


  file { 'C:\Program Files (x86)\Atomia': ensure => 'directory' }

  file { 'C:\Program Files (x86)\Atomia\Common': ensure => 'directory' }

  file { "unattended.ini":
    path    => 'C:\Program Files (x86)\Atomia\Common\unattended.ini',
    ensure  => file,
    content => template('atomia/windows_base/ini_template.erb'),
  }

  file { 'C:\Program Files (x86)\Atomia\Common\atomia.ini.location': content => 'C:\Program Files (x86)\Atomia\Common', }

  file { 'C:\install\recreate_all_config_files.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/recreate_all_config_files.ps1"
  }


  if($::vagrant){
    file { 'c:/install/certificates':
      source  => 'puppet:///modules/atomiacerts/certificates',
      recurse => true
    }
  
    file { 'C:\inetpub\wwwroot\empty.crl':
      ensure => 'file',
      source  => 'puppet:///modules/atomiacerts/empty.crl',
    }    
  }
  else {
    file { 'c:/install/certificates':
      source  => 'puppet:///atomiacerts/certificates',
      recurse => true
    }
  
    file { 'C:\inetpub\wwwroot\empty.crl':
      ensure => 'file',
      source => "puppet:///atomiacerts/empty.crl"
    }
  }
}
