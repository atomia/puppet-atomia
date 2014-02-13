require 'spec_helper'

describe 'atomia::adjoin' do

	# minimum set of default parameters
	let :params do
		{
   			:base_dn         => "cn=Users,dc=atomia,dc=local",
   			:ldap_uris       => "ldap://9.9.9.9 ldap://9.9.9.10",
   			:bind_user       => "PosixGuest",
   			:bind_password   => "PosixGuestPassword",
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
    
    it { should contain_file('/etc/nsswitch.conf').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '644',
				)
	}

	
	
	
	
end

