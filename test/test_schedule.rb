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
end