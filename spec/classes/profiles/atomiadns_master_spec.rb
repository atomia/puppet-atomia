require 'spec_helper'

describe 'atomia::profile::dns::atomiadns_master' do

  let :facts do
    {
      :osfamily		=> 'Debian'
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
end
