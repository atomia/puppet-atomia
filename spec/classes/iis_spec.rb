require 'spec_helper'

describe 'atomia::iis' do

	# minimum set of default parameters
	let :params do
		{
		}
	end
	
    
    it { should contain_file('c:/install/setup_iis.ps1')}
    it { should contain_file('c:/install/IISSharedConfigurationEnabler.exe')}
	it { should contain_file('c:/install/LsaStorePrivateData.exe')}
    it { should contain_file('c:/install/RegistryUnlocker.exe')}


end

