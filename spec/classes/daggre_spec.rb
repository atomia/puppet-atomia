require 'spec_helper'

describe 'atomia::daggre' do

	# minimum set of default parameters
	let :params do
		{
			:global_auth_token		=> 'abc123'
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
    context 'make sure required packages are installed' do
    
		it { should contain_package('daggre').with_ensure('present') }    
	
    end

	it { should contain_file('/etc/default/daggre').with_content(/abc123/) }
	it { should contain_file('/etc/daggre_submit.conf').with_content(/abc123/) }
		
	
	
end

