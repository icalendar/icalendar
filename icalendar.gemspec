Gem::Specification.new do |s|
  s.name = "icalendar"
  s.version = "1.2"
  s.homepage = "http://icalendar.rubyforge.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "A ruby implementation of the iCalendar specification (RFC-2445)."
  s.description = "Implements the iCalendar specification (RFC-2445) in Ruby.  This allows for the generation and parsing of .ics files, which are used by a variety of calendaring applications."

  s.files      = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.require_path = "lib"
  s.autorequire = "icalendar"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "COPYING", "GPL"]
  s.rdoc_options.concat ['--main', 'README']

  s.author = "Sean Dague"
  s.email = "sean@dague.net"
end

