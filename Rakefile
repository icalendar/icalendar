require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/icalendar'

Hoe.plugin :newgem
Hoe.plugin :website

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'icalendar' do
  self.developer 'Sean Dague', 'sean@dague.net'
  self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_rdoc_files = ["README.rdoc"]
  self.readme_file = "README.rdoc"
end

if ENV['UNDER_HUDSON']
  require 'ci/reporter/rake/test_unit'
  task :test => ["ci:setup:testunit"]
end
