# Sets up a local nfs server for test purposes with the shares required for atomia
class atomia::testenvironment::local_nfs_server {
	include nfs::server
	
	file { '/export':
    ensure => directory,
  }

  file { '/export/content':
    ensure => directory,
    require => File["/export"],
     mode    => 755
  }  
  
  file { '/export/configuration':
    ensure => directory,
    require => File["/export"],
     mode    => 755
    }
   
  
	nfs::export { '/export/content':
	  export => {
	    # host           options
	    '127.0.0.1' => 'rw,async,no_root_squash,no_subtree_check',
	  }
	}
	
	 nfs::export { '/export/configuration':
    export => {
      # host           options
      '127.0.0.1' => 'rw,async,no_root_squash,no_subtree_check',
    }
  }

 
}