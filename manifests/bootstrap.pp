class atomia::bootstrap
{
  if $kernel == "Linux" {
     file { "/usr/lib/ruby/vendor_ruby/facter/atomia_role.rb":
       owner  => root,
       group  => root,
       mode   => 755,
       source => "puppet:///modules/atomia/atomia_role.rb"
     }
  }
}
