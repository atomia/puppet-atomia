require 'spec_helper_acceptance'

describe 'atomia::role::dns_master role' do

  describe 'running Puppet code' do

    it 'should run sucessfully' do
      pp = <<-EOS
      include atomia::profile::general::atomia_repository
      #Optimally we should get the variables from hiera but I did not yet
      #figure out how to do this.
      class {'atomia::profile::dns::atomiadns_master':
        atomiadns_password => 'password',
        dns_zones          => ['preview.atomia.com','mysql.atomia.com'],
        nameservers        => ['ns1.atomia.com','ns2.atomia.com'],
        registry           => 'registry.atomia.com'
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to_not be 1
    end

  end

  describe 'AtomiaDNS setup' do

    it 'should have added a nameserver group' do
      $nsgroup_command = '/usr/bin/sudo -u postgres psql zonedata -tA -c \
      "SELECT name FROM nameserver_group WHERE name = \'default\'" |\
       grep ^default\$'
      shell($nsgroup_command, :acceptable_exit_codes => 0)
    end

    it 'should have synced atomiadns config' do
      $config_check_command = 'grep \'http://localhost/atomiadns\' \
      /etc/atomiadns.conf'
      shell($config_check_command, :acceptable_exit_codes => 0)
    end

    it 'should be possible to get one of the added zones' do
      $check_add_zone_command = 'atomiadnsclient --method GetZone \
      --arg preview.atomia.com'
      shell($check_add_zone_command, :acceptable_exit_codes => 0)
    end

  end

end
