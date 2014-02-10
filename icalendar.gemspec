require_relative 'lib/icalendar/version'

Gem::Specification.new do |s|
  s.authors = ['Ryan Ahearn']
  s.email   = ['ryan.c.ahearn@gmail.com']

  s.name = "icalendar"
  s.version = Icalendar::VERSION

  s.homepage = "https://github.com/icalendar/icalendar"
  s.platform = Gem::Platform::RUBY
  s.summary = "A ruby implementation of the iCalendar specification (RFC-5545)."
  s.description = <<-EOD
Implements the iCalendar specification (RFC-5545) in Ruby.  This allows
for the generation and parsing of .ics files, which are used by a
variety of calendaring applications.
  EOD

  s.files = `git ls-files`.split "\n"
  s.test_files = `git ls-files -- {test,spec,features}/*`.split "\n"
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename f }
  s.require_paths = ['lib']

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'tzinfo', '~> 0.3'
  s.add_development_dependency 'activesupport', '~> 3.2'
  s.add_development_dependency 'timecop', '~> 0.7.0'
  s.add_development_dependency 'rspec', '~> 2.14'
  s.add_development_dependency 'simplecov', '~> 0.8'
end

