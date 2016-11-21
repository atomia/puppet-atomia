# Should be placed in /usr/lib/ruby/vendor_ruby/facter/atomia_role.rb
require 'net/http'
require 'uri'
require 'json'

Facter.add('atomia_role_1') do
  setcode do
    serverFQDN = Facter.value(:fqdn)
    if Facter.value(:ec2_public_hostname)
      serverFQDN = Facter.value(:ec2_public_hostname)
    end
    puppetFQDN = getPuppetFQDN()
    JSON.parse(Net::HTTP.get(URI.parse("http://#{puppetFQDN}:3000/servers/roles/#{serverFQDN}")))[0]
  end
end

Facter.add('atomia_role_2') do
  setcode do
    serverFQDN = Facter.value(:fqdn)
    if Facter.value(:ec2_public_hostname)
      serverFQDN = Facter.value(:ec2_public_hostname)
    end
    puppetFQDN = getPuppetFQDN()
    JSON.parse(Net::HTTP.get(URI.parse("http://#{puppetFQDN}:3000/servers/roles/#{serverFQDN}")))[1]
  end
end

Facter.add('atomia_role_3') do
  setcode do
    serverFQDN = Facter.value(:fqdn)
    if Facter.value(:ec2_public_hostname)
      serverFQDN = Facter.value(:ec2_public_hostname)
    end
    puppetFQDN = getPuppetFQDN()
    JSON.parse(Net::HTTP.get(URI.parse("http://#{puppetFQDN}:3000/servers/roles/#{serverFQDN}")))[2]
  end
end

Facter.add('atomia_role_4') do
  setcode do
    serverFQDN = Facter.value(:fqdn)
    if Facter.value(:ec2_public_hostname)
      serverFQDN = Facter.value(:ec2_public_hostname)
    end
    puppetFQDN = getPuppetFQDN()
    JSON.parse(Net::HTTP.get(URI.parse("http://#{puppetFQDN}:3000/servers/roles/#{serverFQDN}")))[3]
  end
end

Facter.add('atomia_role_5') do
  setcode do
    serverFQDN = Facter.value(:fqdn)
    if Facter.value(:ec2_public_hostname)
      serverFQDN = Facter.value(:ec2_public_hostname)
    end
    puppetFQDN = getPuppetFQDN()
    JSON.parse(Net::HTTP.get(URI.parse("http://#{puppetFQDN}:3000/servers/roles/#{serverFQDN}")))[4]
  end
end

def getPuppetFQDN
  contents = File.read('/etc/puppet/puppet.conf')
  server= /server=(.*)/.match(contents)
  server[1]
end
