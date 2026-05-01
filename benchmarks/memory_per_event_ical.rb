require 'memory_profiler'
require 'icalendar'

# Profiles the per-event calendar wrapping pattern:
#   cal = Icalendar::Calendar.new
#   ical_event.parent&.timezones&.each { |tz| cal.add_timezone tz }
#   cal.add_event(ical_event)
#   cal.to_ical

cal_string = File.read(File.join(__dir__, '..', 'spec/fixtures/timezone.ics'))
source_calendar = Icalendar::Calendar.parse(cal_string).first
events = source_calendar.events

ITERATIONS = 1000

report = MemoryProfiler.report do
  ITERATIONS.times do
    events.each do |ical_event|
      cal = Icalendar::Calendar.new
      ical_event.parent&.timezones&.each { |tz| cal.add_timezone tz }
      cal.add_event(ical_event)
      cal.to_ical
    end
  end
end

report.pretty_print(scale_bytes: true, top: 20)
