$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'

# Define a test event
testEvent = <<EOS
BEGIN:VEVENT
UID:19970901T130000Z-123401@host.com
DTSTAMP:19970901T1300Z
DTSTART:19970903T163000Z
DTEND:19970903T190000Z
SUMMARY:Annual Employee Review
CLASS:PRIVATE
CATEGORIES:BUSINESS,HUMAN RESOURCES
END:VEVENT
EOS

class TestEvent < Test::Unit::TestCase

  # Create a calendar with an event for each test.
  def setup
    @cal = Icalendar::Calendar.new
    @event = Icalendar::Event.new
  end

  def test_new
    assert(@event)
  end
  
  # Properties that can only occur once per event
  def test_single_properties
    @event.ip_class = "PRIVATE"
    
    @cal.add_event(@event)
    
    cals = Icalendar::Parser.new(@cal.to_ical).parse
    cal2 = cals.first
    event2 = cal2.events.first
    
    assert_equal("PRIVATE", event2.ip_class)
  end
  
end
