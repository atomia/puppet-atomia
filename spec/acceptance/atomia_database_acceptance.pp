require 'spec_helper_acceptance'

describe 'atomia::atomia_database' do
  let(:manifest) {
    <<-EOS
      class {'atomia::atomia_database':
        atomia_password  => 'password',
      }
    EOS
  }

  it 'should run without errors' do
    result = apply_manifest(manifest)
    expect(@result.exit_code).to_not be 1
  end

  it 'should have setup a cronjob for backups' do
    crontab_exists = shell("sudo -H -u postgres bash -c 'crontab -l' | grep pg_backup  &> /dev/null")
    expect(crontab_exists.exit_code).to eq 0
  end


end
