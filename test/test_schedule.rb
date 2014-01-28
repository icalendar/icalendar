$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'

class TestSchedule < Test::Unit::TestCase
  include Icalendar
  
  test "#transform_byday_to_hash with non-intervalic weekday recurrence ('every saturday')" do
    byday = [
      Icalendar::RRule::Weekday.new("MO", ""),
      Icalendar::RRule::Weekday.new("WE", ""),
      Icalendar::RRule::Weekday.new("FR", "")
    ]

    schedule = Schedule.new(nil);
    assert_equal([:monday, :wednesday, :friday], schedule.transform_byday_to_hash(byday), "Returns array of days when no monthly interval is set")
  end

  test "#transform_byday_to_hash with intervalic weekday recurrence ('every 1st saturday of the month')" do
    byday = [
      Icalendar::RRule::Weekday.new("SA", "1")
    ]

    schedule = Schedule.new(nil);
    assert_equal({saturday: [1]}, schedule.transform_byday_to_hash(byday), "Returns hash with day of week and interval")
  end

  test "#occurrences_between return object that responds to #start_time and #end_time" do
    daily_event = example_event :daily
    schedule = Schedule.new(daily_event)
    example_occurrence = schedule.occurrences_between(Date.parse("2014-02-01"), Date.parse("2014-03-01")).first

    assert_true example_occurrence.respond_to?(:start_time), "Occurrence responds to start_time"
    assert_true example_occurrence.respond_to?(:end_time), "Occurrence responds to end_time"
  end

  test "#occurrences_between return object that responds to #start_time and #end_time (timezoned example)" do
    timezoned_event = example_event :first_saturday_of_month
    schedule = Schedule.new(timezoned_event)
    example_occurrence = schedule.occurrences_between(Date.parse("2014-02-01"), Date.parse("2014-03-01")).first

    assert_true example_occurrence.respond_to?(:start_time), "Occurrence responds to start_time when event has timezone"
    assert_true example_occurrence.respond_to?(:end_time), "Occurrence responds to end_time when event has timezone"
  end


  def example_event(ics_name)
    ics_path = File.expand_path "#{File.dirname(__FILE__)}/fixtures/recurrence_examples/#{ics_name}_event.ics"
    ics_string = File.read(ics_path)
    calendars = Icalendar.parse(ics_string)
    Array(calendars).first.events.first
  end
end