require 'spec_helper'

describe 'atomia::domainreg' do

  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  # minimum set of default parameters
  let :params do
    {
      :service_password => 'abc123',
      :db_password      => 'abc123',
    }
  end

  let :facts do
    {
      :osfamily => 'Debian',
    }
  end

  it { is_expected.to contain_class('atomia::domainreg') }

  # PostgreSQL dumps
  it { is_expected.to contain_file('/opt/postgresql_backup/pg_backup_rotated.sh') }
  it { is_expected.to contain_file('/opt/postgresql_backup/pg_backup.config') }

end
