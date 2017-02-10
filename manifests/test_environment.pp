
class atomia::test_environment (

){

  class { 'atomia::windows_base':
  }

  class { 'atomia::active_directory':
  }

  class { 'atomia::atomia_database':
  }

  class { 'atomia::internal_apps': }
  class { 'atomia::public_apps': }

   Class['atomia::active_directory'] -> Class['atomia::windows_base'] -> Class['atomia::atomia_database'] -> Class['atomia::public_apps'] -> Class['atomia::internal_apps']
}
