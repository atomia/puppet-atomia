# == Class: atomia::role::dns_master
# The dns_master role deploys a complete AtomiaDNS installation
#
# === Parameters
#
# === Actions
#
# === Requires

class atomia::role::dns_master {
  include atomia::profile::general::atomia_repository
  include atomia::profile::dns::atomiadns_master

  Class['atomia::profile::general::atomia_repository'] ->
  Class['atomia::profile::dns::atomiadns_master']
}
