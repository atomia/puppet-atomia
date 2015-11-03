require 'spec_helper'

describe 'atomia::resource_transformations' do

	let :params do
		{
			:hierapath		 => 'spec/hieradata',
			:modulepath	     => "manifests",
            :lookup_var      => "files/lookup_variable.sh"
        }
	end
    

    t_path = "C:/Program Files (x86)/Atomia/AutomationServer/Common/Transformation Files/Resources"

	# Domainreg
	it { should contain_file("#{t_path}.Domainreg.xml")
        .with_content(/http:\/\/localhost\/domainreg/)
        .with_content(/domainreg_password/)
        .with_content(/domainreg_username/)        
    }

    # AtomiaDNS
    it { should contain_file("#{t_path}.Atomiadns.xml")  
        .with_content(/name=\"Username\">atomiadns/) 
        .with_content(/name=\"URL\">http:\/\/localhost\/atomiadns/) 
        .with_content(/name=\"Password\">atomiadns_password/) 
        .with_content(/name=\"Nameservers\">ns1.atomia.com.,ns2.atomia.com./) 
        .with_content(/name=\"NameserverGroup\">default/)
     }

    # ActiveDirectory
    it { should contain_file("#{t_path}.ActiveDirectory.xml")  
        .with_content(/name=\"DomainName\">atomia.local/) 
        .with_content(/name=\"ShortDomainName\">atomia/) 
        .with_content(/name=\"Username\">Administrator/) 
        .with_content(/name=\"Password\">ad_password/) 
     }    
    
    # CronAgent
    it { should contain_file("#{t_path}.CronAgent.xml")  
        .with_content(/name=\"CronBaseUrl\">http:\/\/127.0.0.1:10001/) 
        .with_content(/name=\"AuthToken\">cron_auth_token/) 

     }        
 
    # MySQL
    it { should contain_file("#{t_path}.MySQL.xml")  
        .with_content(/name=\"DatabaseServer\">1.1.1.1/) 
        .with_content(/name=\"DatabaseServer\">1.1.1.2/) 
        .with_content(/name=\"User\">mysql_user/) 
        .with_content(/name=\"Password\">mysql_password/) 
     }
    
 
    # MSSQL
    it { should contain_file("#{t_path}.MSSQL.xml")  
        .with_content(/name=\"DatabaseServer\">1.1.1.1/) 
        .with_content(/name=\"DatabaseServer\">1.1.1.2/) 
        .with_content(/name=\"User\">mssql_user/) 
        .with_content(/name=\"Password\">mssql_password/) 
     }      
    

    # Daggre
    it { should contain_file("#{t_path}.Daggre.xml")  
        .with_content(/name=\"DaggreHosts\">127.0.0.1/) 
        .with_content(/name=\"DaggreAuthToken\">daggre_token/) 
     }

    # Awstats
    it { should contain_file("#{t_path}.Awstats.xml")  
        .with_content(/name=\"URL\">http:\/\/127.0.0.1:8888\/AwstatsAgentService/) 
        .with_content(/name=\"Username\">awstats/) 
        .with_content(/name=\"Password\">awstats_password/) 
        .with_content(/name=\"ReportsSiteIP\">127.0.0.1/) 
     }  
    
    # FSAgent
    it { should contain_file("#{t_path}.FSAgent.xml")  
        .with_content(/name=\"URL\">http:\/\/127.0.0.1:10201/) 
        .with_content(/name=\"Username\">fsagent/) 
        .with_content(/name=\"Password\">fsagent_password/) 
     }  

    # PureFTPD
    it { should contain_file("#{t_path}.PureFTPD.xml")  
        .with_content(/name=\"DatabaseHost\">127.0.0.1/) 
        .with_content(/name=\"Username\">pureftpd/) 
        .with_content(/name=\"Password\">pureftpd_password/)
        .with_content(/name=\"ClusterIpAddress\">2.2.2.2/)
        .with_content(/name=\"FileSystemAgentUrl\">http:\/\/127.0.0.1:10201\//) 
        .with_content(/name=\"FileSystemAgentUsername\">fsagent/) 
        .with_content(/name=\"FileSystemAgentPassword\">fsagent_password/) 
        .with_content(/name=\"StorageRoot\">\/storage\/content/) 
     }    

    # ApacheAgent
    it { should contain_file("#{t_path}.ApacheAgent.xml")  
        .with_content(/name=\"URL\">http:\/\/127.0.0.1:9999\/ApacheAgentService/) 
        .with_content(/name=\"Username\">apacheagent/) 
        .with_content(/name=\"Password\">apacheagent_password/) 
        .with_content(/name=\"ClusterIpAddress\">2.2.2.2/) 
     }    
    
    # PostfixAndDovecot
    it { should contain_file("#{t_path}.MailServer.xml")  
        .with_content(/name=\"DatabaseHost\">2.2.2.2/) 
        .with_content(/name=\"Password\">mailserver_password/) 
        .with_content(/name=\"MailIpAddress\">3.3.3.3/) 
     } 

    # IIS
    it { should contain_file("#{t_path}.IIS.xml")  
        .with_content(/name=\"IPAddress\">2.2.2.2/) 
        .with_content(/name=\"ClusterIpAddress\">3.3.3.3/) 
     } 

end

    
