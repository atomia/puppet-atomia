require 'spec_helper'

describe 'atomia::mysql' do

	# minimum set of default parameters
	let :params do
		{
            :mysql_username     => 'foo',
            :mysql_password     => 'bar',
            :provisioning_host  => '127.0.0.1'
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	

    it { should contain_file('/etc/cron.hourly/ubuntu-mysql-fix') }
    it { should contain_file('/etc/security/limits.conf') }
	
	
end

