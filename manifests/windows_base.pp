## Atomia Windows base

### Deploys all pre requirements for installing Atomia Applications

### Variable documentation
#### appdomain: The domain name to use for all your Atomia applications, atomia.com would mean your applications would get the url hcp.atomia.com, login.atomia.com etc
#### license_key: The license key you received from Atomia
#### actiontrail_host: The subdomain to use for Atomia Actiontrail
#### login_host: The subdomain to use for Atomia Identity
#### store_host: The subdomain to use for Atomia Store
#### billing_host: The subdomain to use for Atomia Billing Customer Panel
#### admin_host: The subdomain to use for Atomia Admin Panel
#### hcp_host: The subdomain to use for Atomia Hosting Control Panel
#### automationserver_host: The subdomain to use for Atomia Automationserver
#### mail_sender_address: The sender email address to use for outgoing email
#### mail_server_host: The mailserver hostname to use for sending email
#### mail_server_port: The port of the mailserver to use for sending email
#### mail_server_username: The mailserver username
#### mail_server_password: The mailserver password
#### mail_server_use_ssl: Does the mailserver use ssl or not
#### mail_reply_to: The Reply to email address for all outgoing email
#### mail_bcc_list: BCC address list for all outgoing email
#### storage_server_hostname: The hostname of the storage server
#### mail_dispatcher_interval: The interval to send email at
#### automationserver_encryption_cert_thumb: The thumbprint for the automation server certificate. This should be prefilled by pressing the generate new certificates button.
#### billing_encryption_cert_thumb: The thumbprint for the billing certificate. This should be prefilled by pressing the generate new certificates button.
#### root_cert_thumb: The thumbprint for the root certificate. This should be prefilled by pressing the generate new certificates button.
#### signing_cert_thumb: The thumbprint for the signing certificate. This should be prefilled by pressing the generate new certificates button.
#### test_env: Set this to true if you are installing a test environment
#### grpc_account_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_account_api_listen_port: The port to listen on for the gRPC Account API endpoint.
#### grpc_account_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_billing_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_billing_api_listen_port: The port to listen on for the gRPC Billing API endpoint.
#### grpc_billing_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_public_order_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_public_order_api_listen_port: The port to listen on for the gRPC Public Order API endpoint.
#### grpc_public_order_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_authorization_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_authorization_api_listen_port: The port to listen on for the gRPC Authorization API endpoint.
#### grpc_authorization_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_config_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_config_api_listen_port: The port to listen on for the gRPC Config API endpoint.
#### grpc_config_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_core_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_core_api_listen_port: The port to listen on for the gRPC Core API endpoint.
#### grpc_core_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_native_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_native_api_listen_port: The port to listen on for the gRPC Native API endpoint.
#### grpc_native_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_user_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_user_api_listen_port: The port to listen on for the gRPC User API endpoint.
#### grpc_user_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.
#### grpc_actiontrail_api_listen_address: The IP address to listen on, default is to listen on all interfaces.
#### grpc_actiontrail_api_listen_port: The port to listen on for the gRPC ActionTrail API endpoint.
#### grpc_actiontrail_api_whitelist: Semicolon separated list of ip addresses and ip ranges that should be able to connect to the gRPC endpoint. To disable whitelisting just leave this empty.

### Validations
##### appdomain: ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$
##### license_key: ^[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}$
##### actiontrail_host(advanced): ^[a-zA-Z0-9]+
##### login_host(advanced): ^[a-zA-Z0-9]+
##### store_host(advanced): ^[a-zA-Z0-9]+
##### billing_host(advanced): ^[a-zA-Z0-9]+
##### admin_host(advanced): ^[a-zA-Z0-9]+
##### hcp_host(advanced): ^[a-zA-Z0-9]+
##### automationserver_host(advanced): ^[a-zA-Z0-9]+
##### mail_sender_address: ^\S+@\S+\.\S+$
##### mail_server_host(advanced): ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z0-9]{1,6}$
##### mail_server_port(advanced): [0-9]{1,3}
##### mail_server_username(advanced): ^[a-zA-Z0-9]+
##### mail_server_password(advanced): .*
##### mail_server_use_ssl(advanced): ^(true|false)+
##### mail_reply_to: ^\S+@\S+\.\S+$
##### mail_bcc_list: ^\S+@\S+\.\S+$
##### storage_server_hostname(advanced): ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z0-9]{1,6}$
##### mail_dispatcher_interval(advanced): [0-9]{1,5}
##### is_iis(advanced): %hide
##### automationserver_encryption_cert_thumb(advanced): .*
##### billing_encryption_cert_thumb(advanced): .*
##### root_cert_thumb(advanced): .*
##### signing_cert_thumb(advanced): .*
##### test_env(advanced): %int_boolean
##### grpc_account_api_listen_address(advanced): .*
##### grpc_account_api_listen_port(advanced): [0-9]+
##### grpc_account_api_whitelist(advanced): .*
##### grpc_billing_api_listen_address(advanced): .*
##### grpc_billing_api_listen_port(advanced): [0-9]+
##### grpc_billing_api_whitelist(advanced): .*
##### grpc_public_order_api_listen_address(advanced): .*
##### grpc_public_order_api_listen_port(advanced): [0-9]+
##### grpc_public_order_api_whitelist(advanced): .*
##### grpc_authorization_api_listen_address(advanced): .*
##### grpc_authorization_api_listen_port(advanced): [0-9]+
##### grpc_authorization_api_whitelist(advanced): .*
##### grpc_config_api_listen_address(advanced): .*
##### grpc_config_api_listen_port(advanced): [0-9]+
##### grpc_config_api_whitelist(advanced): .*
##### grpc_core_api_listen_address(advanced): .*
##### grpc_core_api_listen_port(advanced): [0-9]+
##### grpc_core_api_whitelist(advanced): .*
##### grpc_native_api_listen_address(advanced): .*
##### grpc_native_api_listen_port(advanced): [0-9]+
##### grpc_native_api_whitelist(advanced): .*
##### grpc_user_api_listen_address(advanced): .*
##### grpc_user_api_listen_port(advanced): [0-9]+
##### grpc_user_api_whitelist(advanced): .*
##### grpc_actiontrail_api_listen_address(advanced): .*
##### grpc_actiontrail_api_listen_port(advanced): [0-9]+
##### grpc_actiontrail_api_whitelist(advanced): .*

class atomia::windows_base (
  $appdomain                               = '',
  $license_key                             = '00000000-0000-0000-0000-000000000000',
  $actiontrail_host                        = 'actiontrail',
  $login_host                              = 'login',
  $store_host                              = 'store',
  $billing_host                            = 'billing',
  $admin_host                              = 'admin',
  $hcp_host                                = 'hcp',
  $automationserver_host                   = 'automationserver',
  $mail_sender_address                     = '',
  $mail_server_host                        = '',
  $mail_server_port                        = '25',
  $mail_server_username                    = '',
  $mail_server_password                    = '',
  $mail_server_use_ssl                     = false,
  $mail_reply_to                           = '',
  $mail_bcc_list                           = '',
  $storage_server_hostname                 = '',
  $mail_dispatcher_interval                = '30',
  $automationserver_encryption_cert_thumb,
  $billing_encryption_cert_thumb,
  $root_cert_thumb,
  $signing_cert_thumb,
  $is_iis                                  = '0',
  $enable_mssql                            = false,
  $enable_postgresql                       = true,
  $test_env                                = '0',
  $grpc_account_api_listen_address         = '0.0.0.0',
  $grpc_account_api_listen_port            = '50053',
  $grpc_account_api_whitelist              = '',
  $grpc_billing_api_listen_address         = '0.0.0.0',
  $grpc_billing_api_listen_port            = '50051',
  $grpc_billing_api_whitelist              = '',
  $grpc_public_order_api_listen_address    = '0.0.0.0',
  $grpc_public_order_api_listen_port       = '50052',
  $grpc_public_order_api_whitelist         = '',
  $grpc_authorization_api_listen_address   = '0.0.0.0',
  $grpc_authorization_api_listen_port      = '50054',
  $grpc_authorization_api_whitelist        = '',
  $grpc_config_api_listen_address          = '0.0.0.0',
  $grpc_config_api_listen_port             = '50055',
  $grpc_config_api_whitelist               = '',
  $grpc_core_api_listen_address            = '0.0.0.0',
  $grpc_core_api_listen_port               = '50056',
  $grpc_core_api_whitelist                 = '',
  $grpc_native_api_listen_address          = '0.0.0.0',
  $grpc_native_api_listen_port             = '50057',
  $grpc_native_api_whitelist               = '',
  $grpc_user_api_listen_address            = '0.0.0.0',
  $grpc_user_api_listen_port               = '50058',
  $grpc_user_api_whitelist                 = '',
  $grpc_actiontrail_api_listen_address     = '0.0.0.0',
  $grpc_actiontrail_api_listen_port        = '50059',
  $grpc_actiontrail_api_whitelist          = '',
){

  File { source_permissions => ignore }

  $app_password               = hiera('atomia::active_directory::app_password','')
  $ad_domain                  = hiera('atomia::active_directory::domain_name','')
  $domainreg_service_url      = hiera('atomia::domainreg::service_url','')
  $domainreg_service_username = hiera('atomia::domainreg::service_username','')
  $domainreg_service_password = hiera('atomia::domainreg::service_password','')
  $database_server_host       = hiera('atomia::atomia_database::server_address','')
  $database_server_username   = hiera('atomia::atomia_database::atomia_user','')
  $database_server_password   = hiera('atomia::atomia_database::atomia_password','')
  $order_host                 = 'order'

  if( $is_iis == '0' ){

    if($::vagrant) {
      $actiontrail_ip = $::ipaddress
      $database_server = 'WINMASTER\SQLEXPRESS'
      $mirror_database_server = ''
    }
    else
    {
      $actiontrail_ip = "${actiontrail_host}.${appdomain}"

      # TODO: Get these from hiera
      $database_server = ''
      $mirror_database_server = ''
    }

    # 6.1 is 2008 R2, so this matches 2012 and forward
    # see http://msdn.microsoft.com/en-us/library/windows/desktop/ms724832(v=vs.85).aspx
    if versioncmp($::kernelmajversion, '6.1') > 0 {
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

      dism { 'WCF-HTTP-Activation45':
        ensure => present,
        all    => true,
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

  if (!defined(File['c:/install']) and $::atomia_role_1 != 'test_environment') {
    file { 'c:/install': ensure => 'directory' }
  }

  file { 'c:/install/base.ps1':
    ensure => 'file',
    source => 'puppet:///modules/atomia/windows_base/baseinstall.ps'
  }

  file { 'c:/install/disableweakssl.reg':
    ensure => 'file',
    source => 'puppet:///modules/atomia/windows_base/disableweakssl.reg'
  }

  file { 'c:/install/Windows6.1-KB2554746-x64.msu':
    ensure => 'file',
    source => 'puppet:///modules/atomia/windows_base/Windows6.1-KB2554746-x64.msu'
  }


  # Install Packages with Chocolatey
  exec { 'install-chocolatey':
    command  => "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))",
    provider => powershell,
    onlyif   => 'if (Test-Path "C:\ProgramData\Chocolatey") { exit 1;}  else { exit 0; }',
    notify   => Exec['set-chocolatey-path']
  }

  exec { 'set-chocolatey-path':
    command => 'c:\windows\system32\cmd.exe /c SET PATH=%PATH%;%systemdrive%\ProgramData\chocolatey\bin',
    creates => 'c:/install/chocolatey_installed.txt',
    require => Exec['install-chocolatey'],
    refreshonly => true
  }

  package { 'GoogleChrome':
    ensure   => installed,
    provider => 'chocolatey',
    require  => Exec['set-chocolatey-path'],
  }

  package { 'notepadplusplus':
    ensure   => installed,
    provider => 'chocolatey',
    require  => Exec['set-chocolatey-path'],
  }

  package { 'vcredist2008':
    ensure   => installed,
    provider => 'chocolatey',
    require  => Exec['set-chocolatey-path'],
  }

  if versioncmp($::kernelmajversion, '6.1') == 0 {
    # Install .net40
    file { 'c:/install/install_net40.ps1':
      ensure => 'file',
      source => 'puppet:///modules/atomia/windows_base/install_net40.ps1',
    }

    exec { 'Install-NET40':
      command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\install_net40.ps1',
      creates => 'C:\install\installed_net40.txt',
      require => File['c:/install/install_net40.ps1'],
    }
  }

  # Install certificates
  file { 'C:\install\install_certificates.ps1':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/windows_base/install_certificates.ps1',
    require => File['c:/install/certificates'],
  }
  exec { 'install-certificates':
    command  => 'C:\install\install_certificates.ps1',
    creates  => 'C:\install\install_certificates.txt',
    provider => powershell,
    require  => File['C:\install\install_certificates.ps1'],
  }

  # Install Atomia Installer
  file { 'C:\install\install_atomia_installer.ps1':
    ensure => 'file',
    source => 'puppet:///modules/atomia/windows_base/install_atomia_installer.ps1',
  }

  exec { 'install-atomia-installer':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\install_atomia_installer.ps1',
    creates => 'C:\install\install_atomia_installer.txt',
  }

  file { 'C:\ProgramData\Atomia Installer':
    ensure  => directory,
  }

  file { 'C:\ProgramData\Atomia Installer\appupdater.ini':
    ensure  => 'file',
    source  => 'puppet:///modules/atomia/windows_base/appupdater.ini',
    require => [Exec['install-atomia-installer'], File['C:\ProgramData\Atomia Installer']],
  }

  # Install other requirements
  exec { 'base-install':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\base.ps1',
    creates => 'C:\install\install_base.txt',
  }


  file { 'C:\Program Files (x86)\Atomia': ensure => 'directory' }

  file { 'C:\Program Files (x86)\Atomia\Common': ensure => 'directory' }

  file { 'unattended.ini':
    ensure  => file,
    path    => 'C:\Program Files (x86)\Atomia\Common\unattended.ini',
    content => template('atomia/windows_base/ini_template.erb'),
  }

  file { 'C:\Program Files (x86)\Atomia\Common\atomia.ini.location': content => 'C:\Program Files (x86)\Atomia\Common', }

  file { 'C:\install\recreate_all_config_files.ps1':
    ensure => 'file',
    source => 'puppet:///modules/atomia/windows_base/recreate_all_config_files.ps1'
  }

  file { 'c:/install/stop-atomia-services.ps1':
    source  => 'puppet:///modules/windows_base/stop-atomia-services.ps1',
    require => File['c:/install']
  }

  file { 'c:/install/start-atomia-services.ps1':
    source  => 'puppet:///modules/windows_base/start-atomia-services.ps1',
    require => File['c:/install']
  }

  if($::vagrant){
    file { 'c:/install/certificates':
      source  => 'puppet:///modules/atomiacerts/certificates',
      recurse => true
    }

    file { 'C:\inetpub\wwwroot\empty.crl':
      ensure => 'file',
      source => 'puppet:///modules/atomiacerts/empty.crl',
    }
  }
  else {
    file { 'c:/install/certificates':
      source  => "puppet:///atomiacerts/${::environment}/certificates",
      recurse => true
    }

    file { 'C:\inetpub\wwwroot\empty.crl':
      ensure => 'file',
      source => "puppet:///atomiacerts/${::environment}/empty.crl"
    }

    file { 'c:/install/install_atomia_application.ps1':
      ensure  => 'file',
      source  => 'puppet:///modules/atomia/windows_base/install_atomia_application.ps1',
      require => File['c:/install']
    }

    exec {'install-setuptools':
      command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Executionpolicy Unrestricted -File c:/install/install_atomia_application.ps1 -repository PublicRepository -application "Atomia Setup Tools"',
      require => [File['c:/install/install_atomia_application.ps1'], File['unattended.ini']],
      creates => 'C:\Program Files (x86)\Atomia\Common\ADDT',
    }
  }
}
