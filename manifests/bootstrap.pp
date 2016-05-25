class atomia::bootstrap
{
  if $::kernel == 'Linux' {
    case $::osfamily {
      'RedHat' : { $facter_path = '/usr/share/ruby/vendor_ruby/facter' }
      default  : { $facter_path = '/usr/lib/ruby/vendor_ruby/facter' }
    }
    file { "${facter_path}/atomia_role.rb":
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/atomia/atomia_role.rb'
    }
  }
  if $::kernel == 'windows' {
    file { 'C:\ProgramData\PuppetLabs\facter\facts.d\atomia_role.ps1':
      content => template('atomia/active_directory/atomia_role.ps1.erb'),
    }
  }
}
