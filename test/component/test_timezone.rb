$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'

class TestTimezone < Test::Unit::TestCase

  # Create a calendar with an event for each test.
  def setup
    @cal = Icalendar::Calendar.new
    # Define a test timezone
    @testTimezone = %Q(BEGIN:VTIMEZONE\r\nTZID:America/Chicago\r\nBEGIN:STANDARD\r\nDTSTART:19701101T020000\r\nRRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU\r\nTZNAME:CST\r\nTZOFFSETFROM:-0500\r\nTZOFFSETTO:-0600\r\nEND:STANDARD\r\nBEGIN:DAYLIGHT\r\nDTSTART:19700308TO20000\r\nRRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU\r\nTZNAME:CDT\r\nTZOFFSETFROM:-0600\r\nTZOFFSETTO:-0500\r\nEND:DAYLIGHT\r\nEND:VTIMEZONE\r\n)
  end

  def test_new
    @tz = Icalendar::Timezone.new
    assert(@tz)
  end
  
  def test_raw_generation    
    timezone = Icalendar::Timezone.new
    daylight = Icalendar::Daylight.new
    standard = Icalendar::Standard.new

    timezone.timezone_id =            "America/Chicago"

    daylight.timezone_offset_from =   "-0600"
    daylight.timezone_offset_to =     "-0500"
    daylight.timezone_name =          "CDT"
    daylight.dtstart =                "19700308TO20000"
    daylight.recurrence_rules =       ["FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"]

    standard.timezone_offset_from =   "-0500"
    standard.timezone_offset_to =     "-0600"
    standard.timezone_name =          "CST"
    standard.dtstart =                "19701101T020000"
    standard.recurrence_rules =       ["FREQ=YEARLY;BYMONTH=11;BYDAY=1SU"]

    timezone.add(standard)
    timezone.add(daylight)
    @cal.add(timezone)

      array1 = @testTimezone.split("\r\n").sort
      array2 = @cal.timezones.first.to_ical.split("\r\n").sort
      assert_equal(array1, array2)
  end

  def test_block_creation
    @cal.timezone do
      timezone_id             "America/Chicago"

      daylight do
        timezone_offset_from  "-0600"
        timezone_offset_to    "-0500"
        timezone_name         "CDT"
        dtstart               "19700308TO20000"
        add_recurrence_rule   "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"
      end

      standard do
        timezone_offset_from  "-0500"
        timezone_offset_to    "-0600"
        timezone_name         "CST"
        dtstart               "19701101T020000"
        add_recurrence_rule   "FREQ=YEARLY;BYMONTH=11;BYDAY=1SU"
      end
    end

    # This isn't completely correct, but close enough to get around the ordering issue
    array1 = @testTimezone.split("\r\n").sort
    array2 = @cal.timezones.first.to_ical.split("\r\n").sort
    assert_equal(array1, array2)
  end  
end
