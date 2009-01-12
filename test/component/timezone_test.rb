$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'

class TestTimezone < Test::Unit::TestCase

  # Create a calendar with an event for each test.
  def setup
    @cal = Icalendar::Calendar.new
    # Define a test timezone
    @testTimezone = %Q(BEGIN:VTIMEZONE\r\nTZID:America/Chicago\r\nBEGIN:STANDARD\r\nTZOFFSETTO:-0600\r\nRRULE:FREQ=YEARLY\\;BYMONTH=11\\;BYDAY=1SU\r\nTZOFFSETFROM:-0500\r\nDTSTART:19701101T020000\r\nTZNAME:CST\r\nEND:STANDARD\r\nBEGIN:DAYLIGHT\r\nTZOFFSETTO:-0500\r\nRRULE:FREQ=YEARLY\\;BYMONTH=3\\;BYDAY=2SU\r\nTZOFFSETFROM:-0600\r\nDTSTART:19700308TO20000\r\nTZNAME:CDT\r\nEND:DAYLIGHT\r\nEND:VTIMEZONE\r\n)
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
    assert_equal(@testTimezone, @cal.timezones.first.to_ical)
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
    assert_equal(@testTimezone, @cal.timezones.first.to_ical)
  end  
end
