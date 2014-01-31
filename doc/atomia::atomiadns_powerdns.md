== Class: atomia::atomiadns_powerdns

Manifest to install/configure a powerdns nameserver 

[password]
Define a password for accessing atomiadns
(required) 

[agent_user]
Defines the username for accessing atomiadns
(required)

[atomia_dns_url]
Url of atomiadns endpoint
(required)

[atomia_dns_ns_group]
Nameserver group to subscribe to
(required)

[ssl_enabled]
Defines if ssl is enabled
(optional) Defaults to false


=== Examples

class {'atomia::atomiadns_powerdns':
agent_user => 'atomiadns',
agent_password => 'abc123',
atomia_dns_url => 'http://127.0.0.1/atomiadns',
atomia_dns_ns_group => 'default'
}
