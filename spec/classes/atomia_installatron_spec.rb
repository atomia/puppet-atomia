require 'spec_helper'

describe 'atomia::installatron' do

  let(:facts) do
    {
      :lsbdistcodename        => 'trusty',
      :lsbdistid              => 'Ubuntu',
      :lsbdistrelease         => '14.04',
      :lsbmajdistrelease      => '14.04',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :osfamily               => 'Debian',
      :puppetversion          => Puppet.version,
    }
  end
  let :params do
    {
      :authentication_key => 'abc123',
      :license_key        => 'abc123',
    }
  end

  context 'with defaults' do
    it { is_expected.to contain_file('/usr/local/installatron/http').with_owner('www-data') }
  end

end
