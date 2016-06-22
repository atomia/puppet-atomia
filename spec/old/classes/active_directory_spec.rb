require 'spec_helper'

describe 'atomia::active_directory' do

	# minimum set of default parameters
	let :params do
		{
			:hierapath		 => 'spec/hieradata',
			:modulepath	     => "manifests",
            :lookup_var      => "files/lookup_variable.sh"		
		}
	end
	
    
    it { should contain_file('c:/install/add_users.ps1')}


end

