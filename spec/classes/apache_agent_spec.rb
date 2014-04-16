require 'spec_helper'

describe 'atomia::apache_agent' do

	# minimum set of default parameters
	let :params do
		{
			:password		=> 'abc123',
			:content_share_nfs_location	=> "127.0.0.1:/export/content",
			:config_share_nfs_location	=> "127.0.0.1:/export/configuration",
            :maps_path                  => '/storage/foo/maps'
		}
	end
	
	let :facts do 
		{
			:osfamily		=> 'Debian'
		}
	end
	
    context 'make sure required packages are installed' do
    
		it { should contain_package('atomia-pa-apache').with_ensure('present') }    
		it { should contain_package('atomiastatisticscopy').with_ensure('present') }    
		it { should contain_package('apache2').with_ensure('present') }    
		it { should contain_package('libapache2-mod-fcgid-atomia').with_ensure('present') }    
		it { should contain_package('apache2-suexec-custom-cgroups-atomia').with_ensure('present') }    
		it { should contain_package('php5-cgi').with_ensure('present') }    
		it { should contain_package('libexpat1').with_ensure('present') }    
		it { should contain_package('cgroup-bin').with_ensure('present') }    
		
    end
    
    it { should contain_file('/usr/local/apache-agent/settings.cfg').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '440',
				)
        .with_content(/VHOSTS_MAP_FILE             = \/storage\/foo\/maps\/vhost.map/)
	}

    it { should contain_file('/etc/statisticscopy.conf').with(
    			'owner'   => 'root',
				'group'   => 'root',
				'mode'    => '440',
				)
	}
	
	describe 'with ssl enabled' do
		let(:params) {{ :ssl_enabled => true, :password => 'abc123', :content_share_nfs_location	=> "127.0.0.1:/export/content", :config_share_nfs_location	=> "127.0.0.1:/export/configuration" }}
		
		it { should contain_file('/usr/local/apache-agent/wildcard.key').with(
        	        'owner'   => 'root',
                	'group'   => 'root',
	                'mode'    => '440',
	               	).with_content(/[a-z]/)
	    }
	    

	    
	    it { should contain_file('/usr/local/apache-agent/wildcard.crt').with(
        	        'owner'   => 'root',
                	'group'   => 'root',
	                'mode'    => '440',
	               	).with_content(/[a-z]/)
	    }
	end
	
	it { should contain_file('/var/log/httpd') }
	it { should contain_file('/var/www/cgi-wrappers') }
	
	it { should contain_file('/storage/foo/maps').with(
			'owner'   => 'root',
			'group'   => 'www-data',
			'mode'    => '2750',
			'ensure'  => 'directory'
			)
		}
	
	it { should contain_file('/etc/cgconfig.conf').with(
			'owner'   => 'root',
			'group'   => 'root',
			'mode'    => '444',
			)
		}	

	it { should contain_file('/etc/apache2/conf.d/001-custom-errors').with(
			'owner'   => 'root',
			'group'   => 'root',
			'mode'    => '444',
			)
		}			

	it { should contain_file('/etc/apache2/suexec/www-data').with(
			'owner'   => 'root',
			'group'   => 'root',
			'mode'    => '444',
			)
		}			

    it { should contain_file('/storage/configuration/php_session_path').with(
            'owner'     => 'root',
            'group'     => 'root',
            'mode'      => '1733',
        )
    }

    it { should contain_file('/storage/configuration/php.ini').with(
            'owner'     => 'root',
            'group'     => 'root',
            'mode'      => '644',
        )
    }

    it { should contain_file('/etc/php5/cgi/php.ini') }
		
		
	
	
end

