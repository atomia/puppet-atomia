require 'beaker-rspec'
require 'pry'


install_puppet_on(hosts)

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    # Install module to all hosts
    hosts.each do |host|
      #puppet_module_install(:source => proj_root, :module_name => 'atomia')
      install_dev_puppet_module_on(host, :source => module_root, :module_name => 'atomia', :target_module_path => '/etc/puppet/modules')
      # Install dependencies
      on(host, puppet('module', 'install', 'leinaddm-htpasswd'))
      on(host, puppet('module', 'install', 'puppetlabs-postgresql'))
      on(host, puppet('module', 'install', 'puppetlabs-ntp'))
      # Add more setup code as needed
    end
  end
end