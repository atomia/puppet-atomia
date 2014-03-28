require 'spec_helper'

describe 'atomia::cronagent' do

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
    
		it { should contain_package('atomia-cronagent').with_ensure('present') }    
	
    end

	it { should contain_file('/etc/default/cronagent')
        .with_content(/abc123/)
        .with_content(/MAIL_HOST=localhost/)
        .with_content(/MAIL_HOST=localhost/)
        .with_content(/MAIL_PORT=25/)
        
    }
		
	
	
end

