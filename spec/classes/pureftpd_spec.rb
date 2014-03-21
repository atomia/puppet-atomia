require 'spec_helper'

describe 'atomia::pureftpd' do

	# minimum set of default parameters
	let :params do
		{
	       :agent_password             => 'foo',
	       :master_ip                  => '127.0.0.1',
	       :provisioning_host          => '1.1.1.1',
	       :pureftpd_password          => 'foobar',
           :pureftpd_slave_password    => 'fooo',
	       :ftp_cluster_ip             => '2.2.2.2',
	       :content_share_nfs_location => 'storage.atomia.com:/storage',
           :is_master                  => 1
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	

    it { should contain_file('/etc/pure-ftpd/mysql.schema.sql') }

	
	
end

