require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint'
require 'puppet-lint/tasks/puppet-lint'


LINT_IGNORES = ['rvm']

namespace :lint do
  desc "Check puppet module code style."
  task :ci do
    begin
      require 'puppet-lint'
    rescue LoadError
      fail 'Cannot load puppet-lint, did you install it?'
    end

    success = true
    PuppetLint.configuration.send('disable_autoloader_layout')
    linter = PuppetLint.new
    linter.configuration.log_format =
    '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'
    lintrc = ".puppet-lintrc"
    if File.file?(lintrc)
      File.read(lintrc).each_line do |line|
        check = line.sub(/--no-([a-zA-Z0-9_]*)-check/, '\1').chomp
        linter.configuration.send("disable_#{check}")
      end
    end

    FileList['**/*.pp'].each do |puppet_file|
      if puppet_file.start_with? 'modules'
        parts = puppet_file.split('/')
        module_name = parts[1]
        next if LINT_IGNORES.include? module_name
      end

      puts "Evaluating code style for #{puppet_file}"
      linter.file = puppet_file
      linter.run
      success = false if linter.errors?
    end

    abort "Checking puppet module code style FAILED" if success.is_a?(FalseClass)
  end
end
