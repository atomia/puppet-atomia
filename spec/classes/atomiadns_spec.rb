require 'spec_helper'

describe 'atomia::atomiadns' do

  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  # minimum set of default parameters
  let :params do
    {
      :nameserver1    => 'ns1.atomia.com',
      :registry       => 'registry.atomia.com',
      :nameservers    => '[ns1.atomia.com, ns2.atomia.com]',
      :agent_password => 'abc123',
      :db_password    => 'abc123',
      :zones_to_add   => 'preview.atomia.com, mysql.atomia.com',
    }
  end

  let :facts do
    {
      :osfamily => 'Debian',
    }
  end

  it { is_expected.to contain_class('atomia::atomiadns') }

  # PostgreSQL dumps
  it { is_expected.to contain_file('/opt/postgresql_backup/pg_backup_rotated.sh') }
  it { is_expected.to contain_file('/opt/postgresql_backup/pg_backup.config') }

end
