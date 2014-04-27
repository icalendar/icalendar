$:.push File.expand_path('../lib', __FILE__)
require 'icalendar/base'

Gem::Specification.new do |s|
  s.authors = ['Ryan Ahearn']
  s.email   = ['ryan.c.ahearn@gmail.com']

  s.name = "icalendar"
  s.version = Icalendar::VERSION

  s.homepage = "https://github.com/icalendar/icalendar"
  s.platform = Gem::Platform::RUBY
  s.summary = "A ruby implementation of the iCalendar specification (RFC-2445)."
  s.description = <<-EOD
    Implements the iCalendar specification (RFC-2445) in Ruby.  This allows
    for the generation and parsing of .ics files, which are used by a
    variety of calendaring applications.
  EOD

  s.files = `git ls-files`.split "\n"
  s.test_files = `git ls-files -- {test,spec,features}/*`.split "\n"
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename f }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.2'

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'tzinfo', '~> 0.3'
  s.add_development_dependency 'timecop', '~> 0.6.3'
end
