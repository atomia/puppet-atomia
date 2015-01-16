require 'spec_helper'


describe 'atomia::profile::dns::atomiadns_master' do

  let :facts do
    {
      :atomia_role  => 'atomiadns_master',
      :osfamily		  => 'Debian'
    }
  end

  # Packages
  it { should contain_package('atomiadns-masterserver').with_ensure('present') }
  it { should contain_package('atomiadns-client').with_ensure('present') }

  context 'When SSL is enabled' do

    let :facts do
      {
        :atomia_role		=> 'atomiadns_master_with_cert'
      }
    end

    it { should contain_file('/etc/atomiadns-mastercert.pem')\
      .with_content('mycert')
    }
  end

  it { should_not contain_file('/etc/atomiadns-mastercert.pem') }

  it { should contain_file('/etc/atomiadns.conf.master')\
    .with_content(/\s*soap_password = password*/)}

  it { should contain_file('/usr/bin/atomiadns_config_sync') }

  it { should contain_file('/usr/share/doc/atomiadns-masterserver/zones_to_add.txt')
    .with_content(/\s*preview.atomia.com/ )
    .with_content(/\s*cloud.atomia.com*/)}

  it { should contain_file('/usr/share/doc/atomiadns-masterserver/add_zones.sh')}
end
