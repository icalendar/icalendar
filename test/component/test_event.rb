$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'

unless defined? 1.days
  class Integer
    def days
      self * 60 * 60 * 24
    end
  end
end


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

  def test_proprietary_attributes
    @cal.add_event @event
    @event.x_custom_property = 'My Custom Property'

    result = Icalendar::Parser.new(@cal.to_ical).parse.first.events.first

    assert_equal ['My Custom Property'], result.x_custom_property
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
    # puts "#{@event.dtstart.icalendar_tzid} #{@event.dtstart}"
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
    # puts "#{@event.dtstart.icalendar_tzid} #{@event.dtstart}"
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
    # puts "#{@event.dtstart.icalendar_tzid.inspect} #{@event.dtstart}"
    assert_nil(@event.dtstart.icalendar_tzid)
  end

  def test_dtend_tzid_should_be_nil
    assert_nil(@event.dtend.icalendar_tzid)
  end

end

class TestAllDayEventWithoutTime < Test::Unit::TestCase

  def setup
    src = <<EOS
BEGIN:VCALENDAR
VERSION:2.0
X-WR-CALNAME:New Event
PRODID:-//Apple Computer\, Inc//iCal 2.0//EN
X-WR-RELCALID:3A016BE7-8932-4456-8ABD-C8F7EEC5963A
X-WR-TIMEZONE:Europe/London
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
DTSTART;VALUE=DATE:20090110
DTEND;VALUE=DATE:20090111
SUMMARY:New Event
UID:3829F33C-F601-49AC-A3A5-C3AC4A6A3483
SEQUENCE:4
DTSTAMP:20090109T184719Z
END:VEVENT
END:VCALENDAR
EOS
    @calendar = Icalendar.parse(src).first
    @event = @calendar.events.first
  end

  def test_event_is_parsed
    assert_not_nil(@event)
  end

  def test_dtstart_set_correctly
    assert_equal("20090110", @event.dtstart.to_ical)
  end

end

class TestRecurringEventWithCount < Test::Unit::TestCase
  # DTSTART;TZID=US-Eastern:19970902T090000
  # RRULE:FREQ=DAILY;COUNT=10
  # ==> (1997 9:00 AM EDT)September 2-11

  def setup
    src = <<EOS
BEGIN:VCALENDAR
METHOD:PUBLISH
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:19970901T130000Z-123401@host.com
DTSTAMP:19970901T1300Z
DTSTART:19970902T090000Z
DTEND:19970902T100000Z
RRULE:FREQ=DAILY;COUNT=10
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

  def test_recurrence_rules_should_return_a_recurrence_rule_array
    assert_equal 1, @event.recurrence_rules.length
    assert_kind_of(Icalendar::RRule, @event.recurrence_rules.first)
  end

  def test_occurrences_after_with_start_before_start_at_should_return_count_occurrences
    assert_equal 10, @event.occurrences_starting(Time.utc(1997, 9, 2, 8, 30, 0, 0)).length
  end

#  def test_occurrences_after_with_start_before_start_at_should_return_an_event_with_the_dtstart_as_the_first_event
#    assert_equal @event.dtstart.to_s, @event.occurrences_starting(Time.utc(1997, 9, 2, 8, 30, 0, 0)).first.dtstart.to_s
#  end
#
#  def test_occurrences_after_with_start_before_start_at_should_return_events_with_the_correct_dtstart_values
#    expected = (0..9).map {|delta| (@event.dtstart + delta).to_s}
#    assert_equal expected, @event.occurrences_starting(Time.utc(1997, 9, 2, 8, 30, 0, 0)).map {|occurence| occurence.dtstart.to_s}
#  end
end

class TestEventSchedule < Test::Unit::TestCase
  include Icalendar

  test "occurrences_between with a daily event" do
    daily_event = example_calendar.events.first
    occurrences = daily_event.occurrences_between(daily_event.start.to_time, daily_event.start.to_time + 2.days)
    assert_equal 2,                        occurrences.length,        "Event has 2 occurrences over 3 days"
    assert_equal Time.parse("2014-01-27"), occurrences.first.to_time, "Event occurrs on the 27th"
    assert_equal Time.parse("2014-01-29"), occurrences.last.to_time,  "Event occurrs on the 29th"
  end

  test "schedule" do
    daily_event = example_calendar.events.first
    schedule = daily_event.schedule
    assert_equal daily_event.start.to_time, schedule.start_time,                   "Schedule has the same start time as event"
    assert_equal daily_event.end.to_time,   schedule.end_time,                     "Schedule has the same end time as event"
    assert_equal IceCube::DailyRule,        schedule.recurrence_rules.first.class, "Sets daily recurrence rule"
    assert_equal daily_event.exdate.map(&:to_time), schedule.exception_times
  end

  def example_calendar
    calendars = Icalendar.parse(<<-EOF
BEGIN:VCALENDAR
X-WR-CALNAME:Test Public
X-WR-CALID:f512e378-050c-4366-809a-ef471ce45b09:101165
PRODID:Zimbra-Calendar-Provider
VERSION:2.0
METHOD:PUBLISH
BEGIN:VEVENT
UID:efcb99ae-d540-419c-91fa-42cc2bd9d302
RRULE:FREQ=DAILY;INTERVAL=1
SUMMARY:Every day, except the 28th
X-ALT-DESC;FMTTYPE=text/html:<html><body></body></html>
ORGANIZER;CN=Jordan Raine:mailto:jraine@sfu.ca
DTSTART;VALUE=DATE:20140127
DTEND;VALUE=DATE:20140128
STATUS:CONFIRMED
CLASS:PUBLIC
X-MICROSOFT-CDO-ALLDAYEVENT:TRUE
X-MICROSOFT-CDO-INTENDEDSTATUS:FREE
TRANSP:TRANSPARENT
LAST-MODIFIED:20140113T200625Z
DTSTAMP:20140113T200625Z
SEQUENCE:0
EXDATE;VALUE=DATE:20140128
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER;RELATED=START:-PT5M
DESCRIPTION:Reminder
END:VALARM
END:VEVENT
END:VCALENDAR
    EOF
    )

    Array(calendars).first
  end
end