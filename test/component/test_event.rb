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

class TestEventRecurrence < Test::Unit::TestCase
  include Icalendar

  test "occurrences_between with a daily event" do
    daily_event = example_event :daily
    occurrences = daily_event.occurrences_between(daily_event.start_time, daily_event.start_time + 2.days)

    assert_equal 2,                        occurrences.length,        "Event has 2 occurrences over 3 days"
    assert_equal Time.parse("2014-01-27"), occurrences.first.to_time, "Event occurrs on the 27th"
    assert_equal Time.parse("2014-01-29"), occurrences.last.to_time,  "Event occurrs on the 29th"
  end

  test "occurrences_between with an every-other-day event" do
    every_other_day_event = example_event :every_other_day
    start_time = every_other_day_event.start_time
    occurrences = every_other_day_event.occurrences_between(start_time, start_time + 5.days)

    assert_equal 3, occurrences.length, "Event has 3 occurrences over 6 days"
    assert_equal Time.parse("2014-01-27"), occurrences[0].to_time, "Event occurs on the 27th"
    assert_equal Time.parse("2014-01-29"), occurrences[1].to_time, "Event occurs on the 29th"
    assert_equal Time.parse("2014-01-31"), occurrences[2].to_time, "Event occurs on the 31st"
  end

  test "occurrences_between with an every-monday event" do
    every_monday_event = example_event :every_monday
    start_time = every_monday_event.start_time
    occurrences = every_monday_event.occurrences_between(start_time, start_time + 8.days)

    assert_equal 2, occurrences.length, "Event has 2 occurrences over 8 days"
    assert_equal Time.parse("2014-02-03 at 4pm"), occurrences[0].to_time, "Event occurs on the 3rd"
    assert_equal Time.parse("2014-02-10 at 4pm"), occurrences[1].to_time, "Event occurs on the 10th"
  end

  test "occurrences_between with a mon,wed,fri weekly event" do
    multi_day_weekly_event = example_event :multi_day_weekly
    start_time = multi_day_weekly_event.start_time
    occurrences = multi_day_weekly_event.occurrences_between(start_time, start_time + 7.days)

    assert_equal 3, occurrences.length, "Event has 3 occurrences over 7 days"
    assert_equal Time.parse("2014-02-03 16:00:00 -0800"), occurrences[0].start_time, "Event occurs on the 3rd"
    assert_equal Time.parse("2014-02-05 16:00:00 -0800"), occurrences[1].start_time, "Event occurs on the 10th"
    assert_equal Time.parse("2014-02-07 16:00:00 -0800"), occurrences[2].start_time, "Event occurs on the 10th"
  end

  test "occurrences_between with monthy event (dst example)" do
    on_third_every_two_months_event = example_event :on_third_every_two_months
    start_time = on_third_every_two_months_event.start_time
    occurrences = on_third_every_two_months_event.occurrences_between(start_time, start_time + 60.days)

    assert_equal 2, occurrences.length, "Event has 2 occurrences over 61 days"
    assert_equal Time.parse("2014-02-03 16:00:00 -0800"), occurrences[0].to_time, "Event occurs on February 3rd"
    assert_equal Time.parse("2014-04-03 16:00:00 -0700"), occurrences[1].to_time, "Event occurs on April 3rd"
  end

  test "occurrences_between with yearly event" do
    first_of_every_year_event = example_event :first_of_every_year
    start_time = first_of_every_year_event.start_time
    occurrences = first_of_every_year_event.occurrences_between(start_time, start_time + 365.days)

    assert_equal 2, occurrences.length, "Event has 2 occurrences over 366 days"
    assert_equal Time.parse("2014-01-01"), occurrences[0].to_time, "Event occurs on January 1st, 2014"
    assert_equal Time.parse("2015-01-01"), occurrences[1].to_time, "Event occurs on January 1st, 2015"
  end

  test "occurrences_between with every-weekday daily event" do
    every_weekday_daily_event = example_event :every_weekday_daily
    start_time = every_weekday_daily_event.start_time
    occurrences = every_weekday_daily_event.occurrences_between(start_time, start_time + 6.days)

    assert_equal 5, occurrences.length, "Event has 5 occurrences over 7 days"
    assert_true occurrences.map(&:to_time).include?(Time.parse("2014-01-10")), "Event occurs on Friday January 10th"
    assert_false occurrences.map(&:to_time).include?(Time.parse("2015-01-11")), "Event does not occur on Saturday January 11th"
  end

  test "occurrences_between with daily event with until date" do
    monday_until_friday_event = example_event :monday_until_friday
    start_time = monday_until_friday_event.start_time
    occurrences = monday_until_friday_event.occurrences_between(start_time, start_time + 30.days)

    assert_equal 5, occurrences.length, "Event has 5 occurrences over 31 days"
    assert_true occurrences.map(&:to_time).include?(Time.parse("2014-01-15 at 12pm")), "Event occurs on Wednesday January 15th"
    assert_false occurrences.map(&:to_time).include?(Time.parse("2014-01-18 at 12pm")), "Event does not occur on Saturday January 18th"
  end

  test "occurrences_between with daily event with limited count" do
    everyday_for_four_days = example_event :everyday_for_four_days
    start_time = everyday_for_four_days.start_time
    occurrences = everyday_for_four_days.occurrences_between(start_time, start_time + 30.days)

    assert_equal 4, occurrences.length, "Event has 4 occurrences over 31 days"
    assert_true occurrences.map(&:to_time).include?(Time.parse("2014-01-15 at 12pm")), "Event occurs on Wednesday January 15th"
    assert_false occurrences.map(&:to_time).include?(Time.parse("2014-01-17 at 12pm")), "Event does not occur on Saturday January 18th"
  end

  test "occurrences_between with first saturday of month event" do
    first_saturday_of_month_event = example_event :first_saturday_of_month
    start_time = first_saturday_of_month_event.start_time
    occurrences = first_saturday_of_month_event.occurrences_between(start_time, start_time + 45.days)

    assert_equal 2, occurrences.length, "Event has 2 occurrences over 46 days"
    assert_true occurrences.map(&:to_time).include?(Time.parse("2014-01-04")), "Event occurs on Jan 04"
    assert_true occurrences.map(&:to_time).include?(Time.parse("2014-02-01")), "Event occurs on Feb 08"
  end

  test "occurrences_between for proper count-limited event with first event in the past" do
    one_day_a_month_for_three_months_event = example_event :one_day_a_month_for_three_months
    start_time = one_day_a_month_for_three_months_event.start_time
    occurrences = one_day_a_month_for_three_months_event.occurrences_between(start_time + 30.days, start_time + 90.days)

    assert_equal 2, occurrences.length, "Event has 2 occurrences from 30 days after first event to 90 days after first event"
  end

  test "occurrences_between with UTC times" do
    utc_event = example_event :utc
    occurrences = utc_event.occurrences_between(Time.parse("2014-01-01"), Time.parse("2014-02-01"))
    assert_equal Time.parse("20140114T180000Z"), occurrences.first.start_time, "Event start time is in UTC"
  end

  test "schedule" do
    daily_event = example_event :daily
    schedule = daily_event.schedule
    assert_equal daily_event.start_time, schedule.start_time,                   "Schedule has the same start time as event"
    assert_equal daily_event.end.to_time,   schedule.end_time,                     "Schedule has the same end time as event"
    assert_equal IceCube::DailyRule,        schedule.recurrence_rules.first.class, "Sets daily recurrence rule"
    assert_equal daily_event.exdate.map(&:to_time), schedule.exception_times
  end

  test "#transform_byday_to_hash with non-intervalic weekday recurrence ('every saturday')" do
    byday = [
      Icalendar::RRule::Weekday.new("MO", ""),
      Icalendar::RRule::Weekday.new("WE", ""),
      Icalendar::RRule::Weekday.new("FR", "")
    ]

    event = example_event :daily
    assert_equal([:monday, :wednesday, :friday], event.transform_byday_to_hash(byday), "Returns array of days when no monthly interval is set")
  end

  test "#transform_byday_to_hash with intervalic weekday recurrence ('every 1st saturday of the month')" do
    byday = [
      Icalendar::RRule::Weekday.new("SA", "1")
    ]

    event = example_event :daily
    assert_equal({saturday: [1]}, event.transform_byday_to_hash(byday), "Returns hash with day of week and interval")
  end

  def example_event(ics_name)
    ics_path = File.expand_path "#{File.dirname(__FILE__)}/../fixtures/recurrence_examples/#{ics_name}_event.ics"
    ics_string = File.read(ics_path)
    calendars = Icalendar.parse(ics_string)
    Array(calendars).first.events.first
  end
end

class TestTimeUtil < Test::Unit::TestCase
  include Icalendar

  test "converts DateTimee to Time, preserving UTC offset" do
    utc_datetime = DateTime.parse("20140114T180000Z")
    assert_equal 0, TimeUtil.datetime_to_time(utc_datetime).utc_offset, "UTC datetime converts to time with no offset"

    pst_datetime = DateTime.parse("2014-01-27T12:55:21-08:00")
    assert_equal -8*60*60, TimeUtil.datetime_to_time(pst_datetime).utc_offset, "PST datetime converts to time with 8 hour offset"
  end

  test "converts DateTime to Time correctly" do
    datetime = DateTime.parse("2014-01-27T12:55:21-08:00")
    correct_time = Time.parse("2014-01-27T12:55:21-08:00")
    assert_equal correct_time, TimeUtil.datetime_to_time(datetime), "Converts DateTime to Time object with correct time"
  end

  test "DateTime with icalendar_tzid  overrides utc offset when coverted to a Time object" do
    datetime = DateTime.parse("2014-01-27T12:55:21+00:00")
    datetime.icalendar_tzid = "America/Los_Angeles"
    
    assert_equal Time.parse("2014-01-27T12:55:21-08:00"), TimeUtil.to_time(datetime)
  end

  test "converts Date to Time correctly" do
    assert_equal Time.parse("2014-01-01"), TimeUtil.date_to_time(Date.parse("2014-01-01")), "Converts Date to Time object"
  end

  test ".timezone_to_hour_minute_utc_offset" do
    assert_equal "-08:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles"),                           "Handles negative offsets"
    assert_equal "+01:00", TimeUtil.timezone_to_hour_minute_utc_offset("Europe/Amsterdam"),                              "Handles positive offsets"
    assert_equal "+00:00", TimeUtil.timezone_to_hour_minute_utc_offset("GMT"),                                           "Handles UTC zones"
    assert_equal nil,      TimeUtil.timezone_to_hour_minute_utc_offset("Foo/Bar"),                                       "Returns nil when it doesn't know about the timezone"
    assert_equal "-08:00", TimeUtil.timezone_to_hour_minute_utc_offset("\"America/Los_Angeles\""),                       "Handles quoted strings (you get these from ICS files)"
    assert_equal "-07:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles", Date.parse("2014-05-01")), "Handles daylight savings offset"
  end

  test ".timezone_to_hour_minute_utc_offset (daylight savings cases)" do
    # FYI, daylight savings happens on March 9, 2014 at 2am in -08:00

    assert_equal "-08:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles", DateTime.parse("2014-03-09T01:00:00-08:00")), "Handles very specific daylight savings offset"
    
    embedded_timezone_datetime = DateTime.parse("2014-03-09T02:00:00+00:00")
    embedded_timezone_datetime.icalendar_tzid = "America/Los_Angeles"
    assert_equal "-07:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles", embedded_timezone_datetime), "Handles very specific daylight savings offset"

    embedded_timezone_datetime = DateTime.parse("2014-03-09T03:00:00+00:00")
    embedded_timezone_datetime.icalendar_tzid = "America/Los_Angeles"
    assert_equal "-07:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles", embedded_timezone_datetime), "Handles very specific daylight savings offset"
  end
end