# == Class: atomia::active_directory
#
# The purpose of this class is to setup Active directory 
# It should only be applied on the main domain controller
#
# IMPORTANT!
# The following hiera variables must be defined before applying
# this manifest!
# atomia::windows_base::app_password
# atomia::adjoin::bind_password
# atomia::windows_base::admin_password
#
# === Parameters
#
# === Variables
#
# === Examples
#```
# class {'atomia::active_directory':
#}
#
# === Authors
#
# Stefan Mortensen <stefan.mortensen@atomia.com.com>
#

class atomia::active_directory (){

 file { 'c:/install': ensure => 'directory' }

  file { 'c:/install/add_users.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/active_directory/add_users.ps1.erb"
  }

  file { 'c:/install/sync_time.ps1':
    ensure => 'file',
    source => "puppet:///modules/atomia/active_directory/sync_time.ps1.erb"
  }
  
  exec { 'base-install':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/add_users.ps1',
    creates => 'C:\install\installed'
  }

  exec { 'sync-time':
    command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file c:/install/sync_time.ps1',
  }
}

