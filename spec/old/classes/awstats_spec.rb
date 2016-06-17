require 'spec_helper'

describe 'atomia::awstats' do

	# minimum set of default parameters
	let :params do
		{
			:agent_password		=> 'abc123',
			:content_share_nfs_location	=> "127.0.0.1:/export/content",
			:configuration_share_nfs_location	=> "127.0.0.1:/export/configuration",
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
    context 'make sure required packages are installed' do
    
		it { should contain_package('atomia-pa-awstats').with_ensure('present') }    
		it { should contain_package('atomiaprocesslogs').with_ensure('present') }    
		
    end

		
	
	
end

