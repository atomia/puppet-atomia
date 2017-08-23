require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rake'
require 'rspec/core/rake_task'

#FIXME: disabling the following checks via disable_checks didn't work
PuppetLint.configuration.send('disable_autoloader_layout')
PuppetLint.configuration.send('disable_puppet_url_without_modules')
PuppetLint.configuration.send('disable_parameter_order')

exclude_paths = [
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

#workaround bug https://github.com/rodjek/puppet-lint/issues/331

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
  config.log_format = '%{path}:%{line}:%{check}:%{KIND}:%{message}'
  config.fail_on_warnings = true
  config.disable_checks = [
    "names_containing_uppercase",
    "80chars",
    "140chars",
    "class_inherits_from_params_class",
    "documentation",
    "arrow_on_right_operand_line",
    "parameter_defaults",
  ]
end
#end workaround

desc 'Validate syntax for all manifests.'
PuppetSyntax.exclude_paths = exclude_paths

task :default => [:spec, :syntax, :lint]
