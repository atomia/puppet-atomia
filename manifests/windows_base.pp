
class atomia::windows_base (
  $app_password,
  $ad_domain,
  $database_server,
  $mirror_database_server            = "",
  $appdomain,
  $actiontrail      = "actiontrail",
  $login            = "login",
  $order            = "order",
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
  $storage_server_hostname,
  $mail_dispatcher_interval          = "30",
  $should_have_resource_transformations = 0) 

  {
  dism { 'NetFx3': ensure => present }

  # 6.1 is 2008 R2, so this matches 2012 and forward
  # see http://msdn.microsoft.com/en-us/library/windows/desktop/ms724832(v=vs.85).aspx
  if versioncmp($kernelmajversion, "6.1") > 0 {
    dism { 'NetFx4Extended-ASPNET45': ensure => present }

    dism { 'IIS-NetFxExtensibility45': ensure => present }

    dism { 'IIS-ASPNET45': ensure => present }

    dism { 'MSMQ-Services': ensure => present }

    dism { 'MSMQ': ensure => present }

    dism { 'windows-identity-foundation': ensure => present }

    dism { 'WCF-HTTP-Activation':
      ensure => present,
      all    => true
    }

    dism { 'WCF-HTTP-Activation45':
      ensure => present,
      all    => true
    }
  }

  dism { 'MSMQ-Server': ensure => present }

  # Install IIS and modules
  dism { 'IIS-WebServerRole': ensure => present }

  dism { 'IIS-ISAPIFilter': ensure => present }

  dism { 'IIS-ISAPIExtensions': ensure => present }

  dism { 'IIS-NetFxExtensibility': ensure => present }

  dism { 'IIS-ASPNET': ensure => present }

  dism { 'IIS-CommonHttpFeatures': ensure => present }

  dism { 'IIS-StaticContent': ensure => present }

  dism { 'IIS-DefaultDocument': ensure => present }

  dism { 'IIS-ManagementConsole': ensure => present }

  dism { 'IIS-ManagementService': ensure => present }

  dism { 'IIS-HttpRedirect': ensure => present }

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

  exec { 'base-install':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\base.ps1',
    creates => 'C:\install\installed'
  }

  file { 'C:\Program Files (x86)\Atomia': ensure => 'directory' }

  file { 'C:\Program Files (x86)\Atomia\Common': ensure => 'directory' }

  file { "unattended.ini":
    path    => 'C:\Program Files (x86)\Atomia\Common\unattended.ini',
    ensure  => file,
    content => template('atomia/windows_base/ini_template.erb'),
  }

  file { 'C:\Program Files (x86)\Atomia\Common\atomia.ini.location': content => 'C:\Program Files (x86)\Atomia\Common', }

  file { 'C:\ProgramData\Atomia Installer\appupdater.ini':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/appupdater.ini"
  }

  file { 'C:\install\recreate_all_config_files.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/recreate_all_config_files.ps1"
  }

  file { 'C:\install\installcert.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/windows_base/installcert.ps1"
  }

  file { 'c:/install/certificates':
    source  => 'puppet:///atomiacerts/certificates/certificates',
    recurse => true
  }

  file { 'C:\inetpub\wwwroot\empty.crl':
    ensure => 'file',
    source => "puppet:///atomiacerts/certificates/empty.crl"
  }

  # Deploy resource transformations if needed
  if $should_have_resource_transformations == 1 {

    file { 'Domainreg' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.Domainreg.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.Domainreg.erb') 
    }

    file { 'AtomiaDNS' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.Atomiadns.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.Atomiadns.erb')
    }
        
    file { 'ActiveDirectory' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.ActiveDirectory.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.ActiveDirectory.erb')
    }
  
    file { 'CronAgent' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.CronAgent.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.CronAgent.erb')
    }

    file { 'MySQL' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.MySQL.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.MySQL.erb')
    }   

    file { 'EC2' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.EC2.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.EC2.erb')
    }   

    file { 'Daggre' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.Daggre.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.Daggre.erb')
    }   

    file { 'Awstats' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.Awstats.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.Awstats.erb')
    }   

    file { 'FSAgent' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.FSAgent.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.FSAgent.erb')
    }   

    file { 'Webinstaller' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.Webinstaller.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.Webinstaller.erb')
    }   

    file { 'PureFTPD' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.PureFTPD.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.PureFTPD.erb')
    }   

    file { 'ApacheAgent' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.ApacheAgent.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.ApacheAgent.erb')
    }   

    file { 'PostfixAndDovecot' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.PostfixAndDovecot.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.PostfixAndDovecot.erb')
    }
    
    file { 'IISCluster' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.IIS.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.IIS.erb')
    }
        
    file { 'MSSQL' :
      path    => "C:\\Program Files (x86)\\Atomia\\AutomationServer\\Common\\Transformation Files\\Resources.MSSQL.xml",
      ensure => 'file',
      content  => template('resource_transformations/Resources.MSSQL.erb')
    } 

  }

}
