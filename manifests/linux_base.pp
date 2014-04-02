class atomia::linux_base {

    package { sudo: ensure => present }
        
    include '::ntp'
}
