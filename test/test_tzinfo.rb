$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'
require 'tzinfo'
require 'icalendar/tzinfo'
require 'timecop'

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

  def test_dst_transition
    tz = TZInfo::Timezone.get "America/Los_Angeles"

    # DST transition in America/Los_Angeles
    Timecop.freeze('2013-11-03T01:30:00-08:00') do
      assert_raises(TZInfo::AmbiguousTime) { tz.ical_timezone( tz.now ) }
      assert_raises(TZInfo::AmbiguousTime) { tz.ical_timezone( tz.now, nil ) }
      assert_raises(TZInfo::AmbiguousTime) do 
        TZInfo::Timezone.default_dst = nil
        tz.ical_timezone( tz.now )
      end
      
      assert_nothing_raised { tz.ical_timezone( tz.now, true ) }
      assert_nothing_raised { tz.ical_timezone( tz.now, false ) }
      assert_nothing_raised do 
        TZInfo::Timezone.default_dst = true
        tz.ical_timezone( tz.now )
      end
      assert_nothing_raised do 
        TZInfo::Timezone.default_dst = false
        tz.ical_timezone( tz.now )
      end
    end
  end
end
