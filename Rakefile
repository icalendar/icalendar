require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.pattern = 'test/**/test*.rb'
  t.verbose = true
end

task default: [:test, :build]

task :console do
  require 'irb'
  require 'irb/completion'
  require 'icalendar'
  ARGV.clear
  IRB.start
end
