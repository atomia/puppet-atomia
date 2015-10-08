# Should be placed in /usr/lib/ruby/vendor_ruby/facter/atomia_role.rb
require 'net/http'
require 'uri'
require 'json'

Facter.add('atomia_role_1') do
        setcode do
                serverFQDN = Facter.value(:fqdn)
                puppetFQDN = getPuppetFQDN()
                JSON.parse(open("http://#{puppetFQDN}:3000/roles/#{serverFQDN}/json"))["roles"][0]
        end
end

Facter.add('atomia_role_2') do
        setcode do
                serverFQDN = Facter.value(:fqdn)
                puppetFQDN = getPuppetFQDN()
                JSON.parse(open("http://#{puppetFQDN}:3000/roles/#{serverFQDN}/json"))["roles"][1]
        end
end

Facter.add('atomia_role_3') do
        setcode do
                serverFQDN = Facter.value(:fqdn)
                puppetFQDN = getPuppetFQDN()
                JSON.parse(open("http://#{puppetFQDN}:3000/roles/#{serverFQDN}/json"))["roles"][2]
        end
end


def open(url)
        Net::HTTP.get(URI.parse(url))
end

def getPuppetFQDN
        contents = File.read('/etc/puppet/puppet.conf')
        server= /server=(.*)/.match(contents)
        server[1]
end
