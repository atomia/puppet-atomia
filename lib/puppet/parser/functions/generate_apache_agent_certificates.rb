module Puppet::Parser::Functions
	newfunction(:generate_apache_agent_certificates) do |args|
    	class { 'openssl': }
    		ssl_pkey { '/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.key': 
      		creates => "/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.key"
    	}
   	 	x509_cert { '/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.crt':
        	ensure      => 'present',
        	private_key => '/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.key',
        	days        => 4536,
        	force       => false,
        	creates => "/etc/puppet/modules/atomia/files/apache_agent/apache-agent-wildcard.crt"
    	}
	end
end