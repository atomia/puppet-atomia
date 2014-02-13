require 'spec_helper'

describe 'atomia::atomiarepository' do

	# minimum set of default parameters
	let :params do
		{
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
    it { should contain_file('/etc/apt/sources.list.d/atomia.list').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '440',
				)
	}

    it { should contain_file('/etc/apt/ATOMIA-GPG-KEY.pub').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '440',
				)
	}
	
    it { should contain_file('/etc/apt/apt.conf.d/80atomiaupdate').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '440',
				)
	}
	
	
	
end

