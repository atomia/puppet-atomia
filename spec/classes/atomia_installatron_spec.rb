require 'spec_helper'

describe 'atomia::installatron' do

  let(:facts) do
    {
    :lsbdistid              => 'Ubuntu',
    :operatingsystem        => 'Ubuntu',
    :osfamily               => 'Debian',
    :lsbdistcodename        => 'trusty',
    :puppetversion          => Puppet.version,
    :operatingsystemrelease => '14.04'
    }
  end
	let :params do
    {
      :license_key        => 'abc123',
      :authentication_key => 'abc123'
    }
  end

  context 'with defaults' do
    it { is_expected.to contain_file('/usr/local/installatron/http').with_owner('www-data') }
  end

end
