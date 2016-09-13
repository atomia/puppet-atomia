
class atomia::resource_transformations (
  $hierapath      = '/etc/puppet/hieradata',
  $modulepath     = '/etc/puppet/modules/atomia/manifests',
  $lookup_var     = '/etc/puppet/modules/atomia/files/lookup_variable.sh'
)
{

  file { 'C:/Program Files (x86)/Atomia/AutomationServer/':
    ensure  => 'directory',
  }
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/':
    ensure  => 'directory',
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/'],
  }
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/':
    ensure  => 'directory',
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/'],
  }

  $domainreg_url      = hiera('atomia::domainreg::service_url','')
  $domainreg_username = hiera('atomia::domainreg::service_username','')
  $domainreg_password = hiera('atomia::domainreg::service_password','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Domainreg.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.Domainreg.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $atomiadns_url             = hiera('atomia::atomiadns::atomia_dns_url', '')
  $atomiadns_username        = hiera('atomia::atomiadns::agent_user', '')
  $atomiadns_password        = hiera('atomia::atomiadns::agent_password', '')
  $atomiadns_nameservers     = hiera('atomia::atomiadns::nameservers', '')
  $atomiadns_nameservergroup = hiera('atomia::atomiadns::ns_group', '')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Atomiadns.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.Atomiadns.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $activedirectory_domainname      = hiera('atomia::active_directory::domain_name','')
  $activedirectory_shortdomainname = hiera('atomia::active_directory::netbios_domain_name','')
  $activedirectory_username        = 'WindowsAdmin'
  $activedirectory_password        = hiera('atomia::active_directory::windows_admin_password','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.ActiveDirectory.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.ActiveDirectory.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $cronagent_baseurl = hiera('atomia::cronagent::base_url', '')
  $cronagent_token   = hiera('atomia::cronagent::global_auth_token', '')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.CronAgent.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.CronAgent.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $mysql_serverips = hiera('atomia::mysql::server_ips', '')
  $mysql_user      = hiera('atomia::mysql::mysql_username', '')
  $mysql_password  = hiera('atomia::mysql::mysql_password', '')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MySQL.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.MySQL.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $daggre_host = hiera('atomia::daggre::ip_addr', '')
  $daggre_token = hiera('atomia::daggre::global_auth_token', '')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Daggre.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.Daggre.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $awstats_url      = hiera('atomia::awstats::server_ip','')
  $awstats_username = hiera('atomia::awstats::agent_user','')
  $awstats_password = hiera('atomia::awstats::agent_password','')
  $awstats_reportip = hiera('atomia::awstats::server_ip','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Awstats.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.Awstats.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $fsagent_username = hiera('atomia::fsagent::username','')
  $fsagent_password = hiera('atomia::fsagent::password','')
  $fsagent_url      = hiera('atomia::fsagent::fsagent_ip','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.FSAgent.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.FSAgent.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $pureftp_databasehost    = hiera('atomia::pureftpd::master_ip','')
  $pureftp_username        = hiera('atomia::pureftpd::agent_user','')
  $pureftp_password        = hiera('atomia::pureftpd::pureftpd_password','')
  $pureftp_clusterip       = hiera('atomia::pureftpd::ftp_cluster_ip','')
  $pureftp_fsagenturl      = $fsagent_url
  $pureftp_fsagentusername = $fsagent_username
  $pureftp_fsagentpassword = $fsagent_password
  $pureftp_storageroot     = hiera('atomia::pureftpd::content_mount_point','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.PureFTPD.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.PureFTPD.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $apache_url       = hiera('atomia::apache_agent::apache_agent_ip', '')
  $apache_username  = hiera('atomia::apache_agent::username', '')
  $apache_password  = hiera('atomia::apache_agent::password', '')
  $apache_clusterip = hiera('atomia::apache_agent::cluster_ip', '')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.ApacheAgent.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.ApacheAgent.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $postfix_databasehost = hiera('atomia::mailserver::master_ip','')
  $postfix_password     = hiera('atomia::mailserver::agent_password','')
  $postfix_clusterip    = hiera('atomia::mailserver::cluster_ip','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MailServer.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.PostfixAndDovecot.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Webinstaller.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.Webinstaller.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }


  $installatron_url = hiera('atomia::installatron::installatron_hostname','')
  $installatron_key = hiera('atomia::installatron::authentication_key','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Installatron.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.Installatron.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $iis_ip        = hiera('atomia::iis::first_node','')
  $iis_clusterip = hiera('atomia::iis::cluster_ip','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.IIS.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.IIS.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $mssql_serverips = ''
  $mssql_username  = ''
  $mssql_password  = ''
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MSSQL.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.MSSQL.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }

  $openstack_admin_user       = hiera('atomia::openstack::admin_user','')
  $openstack_admin_password   = hiera('atomia::openstack::admin_password','')
  $openstack_domain           = hiera('atomia::openstack::domain','')
  $openstack_identity_uri     = hiera('atomia::openstack::identity_uri','')
  $openstack_compute_uri      = hiera('atomia::openstack::compute_uri','')
  $openstack_network_uri      = hiera('atomia::openstack::network_uri','')
  $openstack_ceilometer_uri   = hiera('atomia::openstack::ceilometer_uri','')
  $openstack_cinder_uri       = hiera('atomia::openstack::cinder_uri','')
  $openstack_hypervisor       = hiera('atomia::openstack::hypervisor','')
  $openstack_external_gateway = hiera('atomia::openstack::external_gateway','')
  file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.OpenStack.xml' :
    ensure  => 'file',
    content => template('atomia/resource_transformations/Resources.OpenStack.erb'),
    require => File['C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/'],
  }
}
