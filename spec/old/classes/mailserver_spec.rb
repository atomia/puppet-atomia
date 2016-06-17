require 'spec_helper'

describe 'atomia::mailserver' do

	# minimum set of default parameters
	let :params do
		{
            :provisioning_host      => '127.0.0.1',
            :is_master              => 1,
            :master_ip              => '127.0.0.1',
            :agent_password         => 'password123',
            :slave_password         => 'slave123',
            :cluster_ip             => '127.0.0.1'
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	

    it { should contain_file('/etc/postfix/mysql.schema.sql') }
    it { should contain_file('/etc/postfix/master.cf') }
    it { should contain_file('/etc/postfix/mysql_relay_domains_maps.cf') }
    it { should contain_file('/etc/postfix/mysql_virtual_alias_maps.cf') }
    it { should contain_file('/etc/postfix/mysql_virtual_mailbox_maps.cf') }
    it { should contain_file('/etc/postfix/mysql_virtual_transport.cf') }
    it { should contain_file('/etc/dovecot/dovecot.conf') }

end

