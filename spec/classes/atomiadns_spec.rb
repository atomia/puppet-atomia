require 'spec_helper'

describe 'atomia::atomiadns' do

	# minimum set of default parameters
	let :params do
		{
			:dns_ns_group		=> 'default',
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
 

    it { should contain_file('/etc/atomiadns.conf.master').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '444',
				).with_content(/atomiadns/)
	}
end

