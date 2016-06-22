require 'spec_helper'

describe 'atomia::atomia_database' do

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
      :atomia_password => 'abc123',
    }
  end

  context 'with defaults' do
    it { is_expected.to contain_class('atomia::atomia_database') }

    # PostgreSQL dumps
    it { is_expected.to contain_file('/opt/postgresql_backup/pg_backup_rotated.sh') }
    it { is_expected.to contain_file('/opt/postgresql_backup/pg_backup.config') }
  end

end
