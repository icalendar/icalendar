$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'icalendar'

require 'date'
cal = nil

File.open(File.expand_path(File.dirname(__FILE__) + '/recur1.ics')) do |file|
  cal = Icalendar.parse(file).first
end
event = cal.events.first
debugger
puts event.to_ical