require 'rake'
require 'rspec/core/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.pattern = 'spec/*/*_spec.rb'
  t.rspec_opts = File.read("spec/spec.opts").chomp || ""
end

require 'puppet-lint'

desc "Run lint check on puppet manifests"
task :lint do
linter =  PuppetLint.new
  Dir.glob('./demo-puppet/modules//**/*.pp').each do |puppet_file|
    puts "Evaluating #{puppet_file}"
    linter.file = puppet_file
    linter.run
  end
  fail if linter.errors?
 end
