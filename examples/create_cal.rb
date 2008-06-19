#!/usr/bin/env ruby
## Need this so we can require the library from the samples directory
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems' # Unless you install from the tarball or zip.
require 'icalendar'
require 'date'

include Icalendar # Probably do this in your class to limit namespace overlap

## Creating calendars and events is easy.

# Create a calendar with an event (standard method)
cal = Calendar.new
cal.event do
  dtstart       Date.new(2005, 04, 29)
  dtend         Date.new(2005, 04, 28)
  summary     "Meeting with the man."
  description "Have a long lunch meeting and decide nothing..."
  klass       "PRIVATE"
end

## Or you can make events like this
event = Event.new
event.start = DateTime.civil(2006, 6, 23, 8, 30)
event.summary = "A great event!"
cal.add_event(event)

event2 = cal.event  # This automatically adds the event to the calendar
event2.start = DateTime.civil(2006, 6, 24, 8, 30)
event2.summary = "Another great event!"

# Now with support for property parameters
params = {"ALTREP" =>['"http://my.language.net"'], "LANGUAGE" => ["SPANISH"]} 

cal.event do
  dtstart Date.new(2005, 04, 29)
  dtend   Date.new(2005, 04, 28)
  summary "This is a summary with params.", params
end

# We can output the calendar as a string to write to a file, 
# network port, database etc.
cal_string = cal.to_ical
puts cal_string
