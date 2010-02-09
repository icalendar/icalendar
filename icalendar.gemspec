Gem::Specification.new do |s| 
  s.name = "icalendar" 
  s.version = "1.1.1"
  s.homepage = "http://icalendar.rubyforge.org/" 
  s.platform = Gem::Platform::RUBY 
  s.summary = "A ruby implementation of the iCalendar specification (RFC-2445)." 
  s.description = "Implements the iCalendar specification (RFC-2445) in Ruby.  This allows for the generation and parsing of .ics files, which are used by a variety of calendaring applications."

  s.files = [
                 "test/calendar_test.rb", "test/parameter_test.rb",
                 "test/interactive.rb", "test/conversions_test.rb",
                 "test/component_test.rb", "test/parser_test.rb",
                 "test/read_write.rb", "test/fixtures",
                 "test/fixtures/single_event.ics",
                 "test/fixtures/folding.ics",
                 "test/fixtures/simplecal.ics",
                 "test/fixtures/life.ics", "test/component",
                 "test/component/timezone_test.rb",
                 "test/component/todo_test.rb",
                 "test/component/event_test.rb", "test/coverage",
                 "test/coverage/STUB", "lib/icalendar",
                 "lib/icalendar/parameter.rb",
                 "lib/icalendar/component.rb",
                 "lib/icalendar/base.rb", "lib/icalendar/parser.rb",
                 "lib/icalendar/calendar.rb",
                 "lib/icalendar/component",
                 "lib/icalendar/component/alarm.rb",
                 "lib/icalendar/component/todo.rb",
                 "lib/icalendar/component/event.rb",
                 "lib/icalendar/component/journal.rb",
                 "lib/icalendar/component/timezone.rb",
                 "lib/icalendar/component/freebusy.rb",
                 "lib/icalendar/conversions.rb",
                 "lib/icalendar/rrule.rb",
 		 "lib/icalendar/tzinfo.rb",
                 "lib/icalendar/helpers.rb", "lib/meta.rb",
                 "lib/icalendar.rb", "lib/hash_attrs.rb", "docs/rfcs",
                 "docs/rfcs/rfc2446.pdf", "docs/rfcs/rfc2426.pdf",
                 "docs/rfcs/itip_notes.txt", "docs/rfcs/rfc2447.pdf",
                 "docs/rfcs/rfc2425.pdf", "docs/rfcs/rfc2445.pdf",
                 "docs/rfcs/rfc3283.txt", "docs/api", "docs/api/STUB",
                 "examples/single_event.ics", "examples/parse_cal.rb",
                 "examples/create_cal.rb"]
    
  s.files += ["Rakefile", "README", "COPYING", "GPL" ]
  s.require_path = "lib" 
  s.autorequire = "icalendar" 
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README", "COPYING", "GPL"]
  s.rdoc_options.concat ['--main', 'README']

  s.author = "Sean Dague" 
  s.email = "sean@dague.net" 
end 

