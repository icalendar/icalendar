# Test out property parameter functionality
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'date'
require 'test/unit'
require 'icalendar'

class TestComponent < Test::Unit::TestCase

   # Create a calendar with an event for each test.
   def setup
      @cal = Icalendar::Calendar.new
      @event = Icalendar::Event.new
   end

   def test_property_parameters
     params = {"ALTREP" =>['"http://my.language.net"'], "LANGUAGE" => ["SPANISH"]}
      @event.summary("This is a test summary.", params)

      assert_equal params, @event.summary.ical_params

      @cal.add_event @event
      cal_str = @cal.to_ical

      cals = Icalendar::Parser.new(cal_str).parse
      event = cals.first.events.first
      assert_equal params, event.summary.ical_params
   end
end
