Gem::Specification.new do |s|
  s.name = "icalendar"
  s.version = "1.2"

  s.homepage = "http://icalendar.rubyforge.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "A ruby implementation of the iCalendar specification (RFC-2445)."
  s.description = "Implements the iCalendar specification (RFC-2445) in Ruby.  This allows for the generation and parsing of .ics files, which are used by a variety of calendaring applications."

  s.add_development_dependency 'hoe', '~> 3.5'
  s.add_development_dependency 'newgem', '~> 1.5'
  s.add_development_dependency 'rubyforge', '~> 2.0'
  s.add_development_dependency 'rdoc', '~> 4.0'
end

