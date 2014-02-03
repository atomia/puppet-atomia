require 'spec_helper'

describe 'atomia::apache_password_protect' do

  # minimum set of default parameters
  let :params do
    {
      :username	  => 'atomia',
      :password   => 'abc123',
    }
  end
  
  let :facts do 
    {
      :osfamily   => 'Debian'
    }
  end
    

    
    it { should contain_file('/etc/apache2/conf.d/passwordprotect').with(
                  'owner'   => 'root',
                  'group'   => 'root',
                  'mode'    => '440',
                  )
      }
        
end

