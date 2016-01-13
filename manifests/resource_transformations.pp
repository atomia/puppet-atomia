
class atomia::resource_transformations (
        $hierapath      = "/etc/puppet/hieradata",
        $modulepath     = "/etc/puppet/modules/atomia/manifests",
        $lookup_var     = "/etc/puppet/modules/atomia/files/lookup_variable.sh"
    ) 
  {

  
    $domainreg_url = hiera('atomia::domainreg::service_url','')
    $domainreg_username = hiera('atomia::domainreg::service_username','')
    $domainreg_password = hiera('atomia::domainreg::service_password','')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Domainreg.xml' :
        content  => template('atomia/resource_transformations/Resources.Domainreg.erb'),
        ensure => 'file',
    }
        
    $atomiadns_url = hiera('atomia::atomiadns::atomia_dns_url', '')
    $atomiadns_username = hiera('atomia::atomiadns::agent_user', '')
    $atomiadns_password = hiera('atomia::atomiadns::agent_password', '')
    $atomiadns_nameservers = hiera('atomia::atomiadns::nameservers', '')
    $atomiadns_nameserverGroup = hiera('atomia::atomiadns::ns_group', '')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Atomiadns.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Atomiadns.erb')
    }

    $activedirectory_domainName = hiera('atomia::active_directory::domain_name','')
    $activedirectory_shortDomainName = hiera('atomia::active_directory::netbios_domain_name','')
    $activedirectory_username = 'WindowsAdmin'
    $activedirectory_password = hiera('atomia::active_directory::windows_admin_password','')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.ActiveDirectory.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.ActiveDirectory.erb')
    }
    
    $cronagent_baseUrl = hiera('atomia::cronagent::base_url', '')
    $cronagent_token = hiera('atomia::cronagent::global_auth_token', '')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.CronAgent.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.CronAgent.erb')
    }

    $mysql_serverIps = hiera('atomia::mysql::server_ips', '')
    $mysql_user = hiera('atomia::mysql::mysql_username', '')
    $mysql_password = hiera('atomia::mysql::mysql_password', '')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MySQL.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.MySQL.erb')
    }
    
    $daggre_host = hiera('atomia::daggre::ip_addr', '')
    $daggre_token = hiera('atomia::daggre::global_auth_token', '')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Daggre.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Daggre.erb')
    }

    $awstats_url = hiera('atomia::awstats::server_ip','')
    $awstats_username = hiera('atomia::awstats::agent_user','')
    $awstats_password = hiera('atomia::awstats::agent_password','')
    $awstats_reportip = hiera('atomia::awstats::server_ip','')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Awstats.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Awstats.erb')
    }
    
    $fsagent_username = hiera('atomia::fsagent::username','')
    $fsagent_password = hiera('atomia::fsagent::password','')
    $fsagent_url = hiera('atomia::fsagent::fsagent_ip','')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.FSAgent.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.FSAgent.erb')
    }
    
    $pureftp_databaseHost = hiera('atomia::pureftpd::master_ip','')
    $pureftp_username = hiera('atomia::pureftpd::agent_user','')
    $pureftp_password = hiera('atomia::pureftpd::agent_password','')
    $pureftp_clusterIp = hiera('atomia::pureftpd::ftp_cluster_ip','')
    $pureftp_fsAgentUrl = $fsagent_url
    $pureftp_fsagentUsername = $fsagent_username
    $pureftp_fsagentPassword = $fsagent_password
    $pureftp_storageRoot = hiera('atomia::pureftpd::content_mount_point','')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.PureFTPD.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.PureFTPD.erb')
    }

    $apache_url = hiera('atomia::apache::apache_agent_ip', '')
    $apache_username = hiera('atomia::apache::username', '')
    $apache_password = hiera('atomia::apache::password', '')
    $apache_clusterIp = hiera('atomia::apache::cluster_ip', '')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.ApacheAgent.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.ApacheAgent.erb')
    }
    
    $postfix_databaseHost = hiera('atomia::mailserver::master_ip','')
    $postfix_password = hiera('atomia::mailserver::agent_password','')
    $postfix_clusterIp = hiera('atomia::mailserver::cluster_ip','')
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MailServer.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.PostfixAndDovecot.erb')
    }
 
    #TODO: Fix these 2
    $iis_ip = ''
    $iis_clusterIp = ''
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.IIS.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.IIS.erb')
    }
    
    $mssql_serverIps = ''
    $mssql_username = ''
    $mssql_password = ''
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MSSQL.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.MSSQL.erb')
    }
    


    



}
