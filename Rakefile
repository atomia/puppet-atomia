require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

#FIXME: disabling autoloader via disable_checks didn't work
PuppetLint.configuration.send("disable_autoloader_layout")


exclude_paths = [
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

#workaround bug https://github.com/rodjek/puppet-lint/issues/331

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
  config.log_format = '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'
  config.disable_checks = [
    "80chars",
    "class_inherits_from_params_class",
    "documentation",
    "parameter_defaults",
  ]
end
#end workaround

desc 'Validate syntax for all manifests.'
PuppetSyntax.exclude_paths = exclude_paths

#only check for syntax and lint for now, add spec testing later
#task :default => [:spec, :syntax, :lint]
task :default => [:syntax, :lint]
