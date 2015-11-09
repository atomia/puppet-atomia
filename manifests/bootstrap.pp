class atomia::bootstrap
{
  if $kernel == "Linux" {
     file { "/usr/lib/ruby/vendor_ruby/facter/atomia_role.rb":
       owner  => root,
       group  => root,
       mode   => "755",
       source => "puppet:///modules/atomia/atomia_role.rb"
     }
  }
  if $kernel == "windows" {
    file { "C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role.ps1":
      content => template('atomia/active_directory/atomia_role.ps1.erb'),
    }
  }
}
