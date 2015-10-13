
class atomia::resource_transformations (
        $hierapath      = "/etc/puppet/hieradata",
        $modulepath     = "/etc/puppet/modules/atomia/manifests",
        $lookup_var     = "/etc/puppet/modules/atomia/files/lookup_variable.sh"
    ) 
  {

    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Domainreg.xml' :
       ensure => 'file',
       content  => template('atomia/resource_transformations/Resources.Domainreg.erb'),
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Atomiadns.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Atomiadns.erb')
    }

    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.ActiveDirectory.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.ActiveDirectory.erb')
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.CronAgent.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.CronAgent.erb')
    }

    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MySQL.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.MySQL.erb')
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Daggre.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Daggre.erb')
    }

    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Awstats.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Awstats.erb')
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.FSAgent.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.FSAgent.erb')
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.Installatron.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.Installatron.erb')
    }
        
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.PureFTPD.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.PureFTPD.erb')
    }

    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.ApacheAgent.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.ApacheAgent.erb')
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MailServer.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.PostfixAndDovecot.erb')
    }
 
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.IIS.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.IIS.erb')
    }
    
    file { 'C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources.MSSQL.xml' :
      ensure => 'file',
      content  => template('atomia/resource_transformations/Resources.MSSQL.erb')
    }

}
