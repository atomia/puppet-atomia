require 'spec_helper'

describe 'atomia::rsyslog' do
    
    let :params do
        {
            :server_ip   => "127.0.0.1" 
        }
    end

    describe 'as an rsyslog client' do
    
        it { should contain_file('/etc/apache2/conf.d/log-to-syslog.conf').with_content(/ErrorLog syslog/) }
        it { should contain_file('/etc/rsyslog.d/atomia-rsyslog-client.conf').with_content(/\*\.\* @127\.0\.0\.1:514/) }

    end

    describe 'as a rsyslog server' do
        let(:params) {{ :is_server => true, :server_ip => "127.0.0.1"}}
        it { should contain_file('/etc/rsyslog.d/atomia-rsyslog-server.conf') }
    end
end
