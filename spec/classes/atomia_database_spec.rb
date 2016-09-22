require 'spec_helper'

describe 'atomia::atomia_database' do

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
