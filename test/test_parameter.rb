# Test out property parameter functionality
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'pp'
require 'date'
require 'test/unit'
require 'icalendar'

class TestParameter < Test::Unit::TestCase

   # Create a calendar with an event for each test.
  def setup
    @cal = Icalendar::Calendar.new
    @event = Icalendar::Event.new
  end

  def test_property_parameters
    tests = [
             {"ALTREP" =>['"http://my.language.net"'],
               "LANGUAGE" => ["SPANISH"]},
             {"ALTREP" =>['"http://my.language.net"'],
               "LANGUAGE" => ['"SPANISH:CATILLAN"']},
             {"ALTREP" =>["foo"],
               "LANGUAGE" => ["SPANISH"]}
             ]

    tests.each do |params|
      @event.summary("This is a test summary.", params)

      assert_equal params, @event.summary.ical_params

      @cal.add_event @event
      cal_str = @cal.to_ical

      cals = Icalendar::Parser.new(cal_str).parse
      event = cals.first.events.first
      assert_equal params, event.summary.ical_params
    end
  end

  def test_unquoted_property_parameters
    params = {'ALTREP' => ['"http://my.language.net"'],
              'LANGUAGE' => ['SPANISH:CATILLAN']}
    expected_params = {'ALTREP' => ['"http://my.language.net"'],
                       'LANGUAGE' => ['"SPANISH:CATILLAN"']}
    @event.summary('This is a test summary.', params)

    assert_equal params, @event.summary.ical_params

    @cal.add_event @event
    cal_str = @cal.to_ical

    cals = Icalendar::Parser.new(cal_str).parse
    event = cals.first.events.first
    assert_equal expected_params, event.summary.ical_params
  end

  def test_nonstandard_property_parameters
    params = {'CUSTOM' => ['yours']}
    @event.priority(2, params)

    assert_equal params, @event.priority.ical_params

    @cal.add_event @event
    cal_str = @cal.to_ical

    cals = Icalendar::Parser.new(cal_str).parse
    event = cals.first.events.first
    assert_equal params, event.priority.ical_params
  end
end
