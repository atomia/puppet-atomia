require 'spec_helper'

describe 'atomia::active_directory' do

	# minimum set of default parameters
	let :params do
		{
		}
	end
	
    
    it { should contain_file('c:/install/add_users.ps1')}


end

