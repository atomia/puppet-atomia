require 'spec_helper'

describe 'atomia::fsagent' do

	# minimum set of default parameters
	let :params do
		{
			:password		=> 'abc123'
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
    context 'make sure required packages are installed' do
    
		it { should contain_package('atomia-fsagent').with_ensure('present') }    
	
    end

    it { should contain_file('/etc/default/fsagent').with_content(/abc123/)}

		
	
	
end

