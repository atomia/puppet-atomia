# == Class: atomia::role::dns_master
# The dns_master role deploys a complete AtomiaDNS installation
#
# === Parameters
#
# === Actions
#
# === Requires

class atomia::role::dns_master {
  class { '::atomia::profile::dns::atomiadns_master'}
}
