require 'spec_helper'

describe 'atomia::atomiadns_powerdns' do

	# minimum set of default parameters
	let :params do
		{
			:agent_user			=> 'atomiadns',
  			:agent_password 	=> 'abc123',
  			:atomia_dns_url		=> 'http://127.0.0.1/atomiadns',
  			:atomia_dns_ns_group => 'default'
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian',
			:operatingsystem => 'Ubuntu'
		}
	end
	
    context 'make sure required packages are installed' do
    
		it { should contain_package('atomiadns-powerdns-database').with_ensure('present') }    
		it { should contain_package('atomiadns-powerdnssync').with_ensure('present') }    
		it { should contain_package('pdns-static').with_ensure('present') }    
		it { should contain_package('dnsutils').with_ensure('present') }   
		 
    end
    
    describe 'debian specific packages' do 
    	let(:facts) {{ :osfamily => 'Debian', :operatingsystem => 'Debian' }}
    	it { should contain_package('bind-utils').with_ensure('present') }   
    end
    
    it { should contain_file('/etc/atomiadns.conf.powerdnssync').with_content(/abc123/) }
    it { should contain_file('/etc/atomiadns.conf.powerdnssync').with_content(/;soap_cacert = \/etc\/atomiadns-mastercert\.pem/) }
    it { should contain_file('/usr/bin/atomiadns_config_sync') }
    
    describe 'ssl is enabled' do 
		let :params do
			{
				:agent_user			=> 'atomiadns',
	  			:agent_password 	=> 'abc123',
	  			:atomia_dns_url		=> 'http://127.0.0.1/atomiadns',
	  			:atomia_dns_ns_group => 'default',
	  			:ssl_enabled		=> 1
			}
		end
		
		 it { should contain_file('/etc/atomiadns.conf.powerdnssync').with_content(/^soap_cacert = \/etc\/atomiadns-mastercert\.pem/) }
    end
   
   
	
	
end

