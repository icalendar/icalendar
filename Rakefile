require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task default: [:spec, :build]

task :console do
  require 'irb'
  require 'irb/completion'
  require 'icalendar'
  ARGV.clear
  IRB.start
end
