require 'spec_helper'

describe 'atomia::service_files' do

	# minimum set of default parameters
	let :params do
		{
		}
	end
	
    
    it { should contain_file('/storage/content/systemservices/public_html/forward.php')}
    it { should contain_file('/storage/content/systemservices/public_html/index.php')}
    it { should contain_file('/storage/content/systemservices/public_html/suspend.php')}
    it { should contain_file('/storage/content/systemservices/public_html/nostats.html')}
    it { should contain_file('/storage/content/00/100000/index.html.default')}

end

