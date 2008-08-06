--- !ruby/object:Gem::Specification 
name: icalendar
version: !ruby/object:Gem::Version 
  version: 1.0.2
platform: ""
authors: 
- Jeff Rose
autorequire: icalendar
bindir: bin
cert_chain: 
date: 2007-11-24 00:00:00 -06:00
default_executable: 
dependencies: []

description: Implements the iCalendar specification (RFC-2445) in Ruby.  This allows for the generation and parsing of .ics files, which are used by a variety of calendaring applications.
email: rosejn@gmail.com
executables: []

extensions: []

extra_rdoc_files: 
- README
- COPYING
- GPL
files: 
- test/component
- test/component/event_test.rb
- test/component/todo_test.rb
- test/parameter_test.rb
- test/interactive.rb
- test/coverage
- test/component_test.rb
- test/fixtures
- test/fixtures/simplecal.ics
- test/fixtures/folding.ics
- test/fixtures/single_event.ics
- test/fixtures/life.ics
- test/read_write.rb
- test/calendar_test.rb
- test/parser_test.rb
- test/conversions_test.rb
- lib/icalendar
- lib/icalendar/component
- lib/icalendar/component/alarm.rb
- lib/icalendar/component/event.rb
- lib/icalendar/component/freebusy.rb
- lib/icalendar/component/journal.rb
- lib/icalendar/component/timezone.rb
- lib/icalendar/component/todo.rb
- lib/icalendar/conversions.rb
- lib/icalendar/parameter.rb
- lib/icalendar/component.rb
- lib/icalendar/helpers.rb
- lib/icalendar/parser.rb
- lib/icalendar/calendar.rb
- lib/icalendar/base.rb
- lib/hash_attrs.rb
- lib/icalendar.rb
- lib/meta.rb
- docs/api
- docs/rfcs
- docs/rfcs/itip_notes.txt
- docs/rfcs/rfc2425.pdf
- docs/rfcs/rfc2426.pdf
- docs/rfcs/rfc2445.pdf
- docs/rfcs/rfc2446.pdf
- docs/rfcs/rfc2447.pdf
- docs/rfcs/rfc3283.txt
- examples/single_event.ics
- examples/create_cal.rb
- examples/parse_cal.rb
- Rakefile
- README
- COPYING
- GPL
has_rdoc: true
homepage: http://icalendar.rubyforge.org/
post_install_message: 
rdoc_options: 
- --main
- README
require_paths: 
- bin
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">"
    - !ruby/object:Gem::Version 
      version: 0.0.0
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: 
rubygems_version: 0.9.5
signing_key: 
specification_version: 1
summary: A ruby implementation of the iCalendar specification (RFC-2445).
test_files: []

