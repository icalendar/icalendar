require 'hoe'
require 'fileutils'
require './lib/icalendar'

Hoe.plugin :newgem
Hoe.plugin :website
Hoe.plugins.delete :gemcutter
Hoe.plugin :rubyforge

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'icalendar' do
  developer 'Ryan Ahearn', 'ryan.c.ahearn@gmail.com'
  self.extra_rdoc_files += %w[COPYING GPL]
end

if ENV['UNDER_HUDSON']
  require 'ci/reporter/rake/test_unit'
  task :test => ["ci:setup:testunit"]
end
