$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'
require 'tzinfo'
require 'icalendar/tzinfo'

class TestTZInfoExt < Test::Unit::TestCase
  def setup
    tz = TZInfo::Timezone.get("Europe/Copenhagen")
    @timezone = tz.ical_timezone(DateTime.new(1970))
  end

  def test_daylight_offset
    tz_offset_from = @timezone.instance_variable_get("@components")[:daylights][0].properties["tzoffsetfrom"]
    tz_offset_to = @timezone.instance_variable_get("@components")[:daylights][0].properties["tzoffsetto"]
    assert_equal(tz_offset_from, "+0100")
    assert_equal(tz_offset_to, "+0200")
  end

  def test_standard_offset
    tz_offset_from = @timezone.instance_variable_get("@components")[:standards][0].properties["tzoffsetfrom"]
    tz_offset_to = @timezone.instance_variable_get("@components")[:daylights][0].properties["tzoffsetto"]
    assert_equal(tz_offset_from, "+0200")
    assert_equal(tz_offset_to, "+0200")
  end
end
