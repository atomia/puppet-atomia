source 'https://rubygems.org'

group :development, :test do
  gem 'rspec'
  gem 'rake'
  gem 'rspec-puppet'    
  gem 'puppetlabs_spec_helper'
  gem 'puppet-lint', '~> 0.3.2'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end


