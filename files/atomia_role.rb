# Should be placed in /usr/lib/ruby/vendor_ruby/facter/atomia_role.rb
require 'net/http'
require 'uri'
require 'json'

Facter.add('atomia_roles') do
        setcode do
                serverFQDN = Facter.value(:fqdn)
                puppetFQDN = getPuppetFQDN()
                JSON.parse(open("http://#{puppetFQDN}:3000/roles/#{serverFQDN}/json"))["roles"]
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
