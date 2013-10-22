$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'
require 'tzinfo'
require 'icalendar/tzinfo'

class TestTZInfoExt < Test::Unit::TestCase
  def setup
    tz = TZInfo::Timezone.get 'Europe/Copenhagen'
    @timezone = tz.ical_timezone DateTime.new(1970)
  end

  def test_daylight_offset
    tz_offset_from = @timezone.instance_variable_get("@components")[:daylights][0].properties["tzoffsetfrom"]
    tz_offset_to = @timezone.instance_variable_get("@components")[:daylights][0].properties["tzoffsetto"]
    assert_equal "+0100", tz_offset_from
    assert_equal "+0200", tz_offset_to
  end

  def test_standard_offset
    tz_offset_from = @timezone.instance_variable_get("@components")[:standards][0].properties["tzoffsetfrom"]
    tz_offset_to = @timezone.instance_variable_get("@components")[:standards][0].properties["tzoffsetto"]
    assert_equal "+0200", tz_offset_from
    assert_equal "+0100", tz_offset_to
  end

  def test_no_end_transition
    tz = TZInfo::Timezone.get('America/Cayman').ical_timezone DateTime.now
    assert_equal <<-EXPECTED.gsub("\n", "\r\n"), tz.to_ical
BEGIN:VTIMEZONE
TZID:America/Cayman
BEGIN:STANDARD
DTSTART:19120201T000711
TZNAME:EST
TZOFFSETFROM:-0652
TZOFFSETTO:-0500
END:STANDARD
END:VTIMEZONE
    EXPECTED
  end

  def test_no_transition
    tz = TZInfo::Timezone.get('UTC').ical_timezone DateTime.now
    assert_equal <<-EXPECTED.gsub("\n", "\r\n"), tz.to_ical
BEGIN:VTIMEZONE
TZID:UTC
BEGIN:STANDARD
DTSTART:19700101T000000
TZNAME:UTC
TZOFFSETFROM:+0000
TZOFFSETTO:+0000
END:STANDARD
END:VTIMEZONE
    EXPECTED
  end
end
