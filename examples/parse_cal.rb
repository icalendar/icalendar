#!/usr/bin/env ruby
## Need this so we can require the library from the samples directory
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'icalendar'
require 'date'
  
# Open a file or string to parse
cal_file = File.open("../test/life.ics")

# Parser returns an array of calendars because a single file
# can have multiple calendar objects.
cals = Icalendar::parse(cal_file)
cal = cals.first

# Now you can access the cal object in just the same way I created it
event = cal.events.first

puts "start date-time: " + event.dtstart.to_s
puts "summary: " + event.summary
