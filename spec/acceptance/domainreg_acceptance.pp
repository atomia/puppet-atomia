require 'spec_helper_acceptance'

describe 'atomia::domainreg' do
  let(:manifest) {
    <<-EOS
        class { 'atomia::linux_base': }
        class {'atomia::atomiarepository': }
        class {'atomia::domainreg':
            service_password => 'abc123',
            db_password      => 'abc123',
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

  it 'should create a database backup of zonedata' do
    create_backup = shell("sudo -H -u postgres bash -c '/opt/postgresql_backup/pg_backup_rotated.sh' &> /dev/null")
    expect(create_backup.exit_code).to eq 0
    backup_created = shell("sudo -H -u postgres bash -c \"/usr/bin/find /opt/atomia_backups/ -type f -name 'zonedata.sql.gz'| /bin/egrep '.*'\"")
    expect(backup_created.exit_code).to eq 0
  end


end
