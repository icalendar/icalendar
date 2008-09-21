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

class TestEventWithSpecifiedTimezone < Test::Unit::TestCase
  
  def setup
    src = <<EOS
BEGIN:VCALENDAR
METHOD:PUBLISH
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:19970901T130000Z-123401@host.com
DTSTAMP:19970901T1300Z
DTSTART;TZID=America/Chicago:19970903T163000
DTEND;TZID=America/Chicago:19970903T190000
SUMMARY:Annual Employee Review
CLASS:PRIVATE
CATEGORIES:BUSINESS,HUMAN RESOURCES
END:VEVENT
END:VCALENDAR
EOS
    @calendar = Icalendar.parse(src).first
    @event = @calendar.events.first
  end
  
  def test_event_is_parsed
    assert_not_nil(@event)
  end
  
  def test_dtstart_should_understand_icalendar_tzid
    assert_respond_to(@event.dtstart, :icalendar_tzid)
  end
  
  def test_dtstart_tzid_should_be_correct
    puts "#{@event.dtstart.icalendar_tzid} #{@event.dtstart}"
    assert_equal("America/Chicago",@event.dtstart.icalendar_tzid)
  end
  
  def test_dtend_tzid_should_be_correct
    assert_equal("America/Chicago",@event.dtend.icalendar_tzid)
  end
  
end

class TestEventWithZuluTimezone < Test::Unit::TestCase
  
  def setup
    src = <<EOS
BEGIN:VCALENDAR
METHOD:PUBLISH
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:19970901T130000Z-123401@host.com
DTSTAMP:19970901T1300Z
DTSTART:19970903T163000Z
DTEND:19970903T190000Z
SUMMARY:Annual Employee Review
CLASS:PRIVATE
CATEGORIES:BUSINESS,HUMAN RESOURCES
END:VEVENT
END:VCALENDAR
EOS
    @calendar = Icalendar.parse(src).first
    @event = @calendar.events.first
  end
  
  def test_event_is_parsed
    assert_not_nil(@event)
  end
  
  def test_dtstart_tzid_should_be_correct
    puts "#{@event.dtstart.icalendar_tzid} #{@event.dtstart}"
    assert_equal("UTC",@event.dtstart.icalendar_tzid)
  end
  
  def test_dtend_tzid_should_be_correct
    assert_equal("UTC",@event.dtend.icalendar_tzid)
  end
  
end

class TestEventWithFloatingTimezone < Test::Unit::TestCase
  
  def setup
    src = <<EOS
BEGIN:VCALENDAR
METHOD:PUBLISH
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:19970901T130000Z-123401@host.com
DTSTAMP:19970901T1300Z
DTSTART:19970903T163000
DTEND:19970903T190000
SUMMARY:Annual Employee Review
CLASS:PRIVATE
CATEGORIES:BUSINESS,HUMAN RESOURCES
END:VEVENT
END:VCALENDAR
EOS
    @calendar = Icalendar.parse(src).first
    @event = @calendar.events.first
  end
  
  def test_event_is_parsed
    assert_not_nil(@event)
  end
  
  def test_dtstart_tzid_should_be_nil
    puts "#{@event.dtstart.icalendar_tzid.inspect} #{@event.dtstart}"
    assert_nil(@event.dtstart.icalendar_tzid)
  end
  
  def test_dtend_tzid_should_be_nil
    assert_nil(@event.dtend.icalendar_tzid)
  end
  
end
