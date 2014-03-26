$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'test/unit'
require 'icalendar'
require 'timecop'

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
    Timecop.freeze("2014-01-01") # avoids DST changing offsets on us
    assert_equal "-08:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles"),                           "Handles negative offsets"
    assert_equal "+01:00", TimeUtil.timezone_to_hour_minute_utc_offset("Europe/Amsterdam"),                              "Handles positive offsets"
    assert_equal "+00:00", TimeUtil.timezone_to_hour_minute_utc_offset("GMT"),                                           "Handles UTC zones"
    assert_equal nil,      TimeUtil.timezone_to_hour_minute_utc_offset("Foo/Bar"),                                       "Returns nil when it doesn't know about the timezone"
    assert_equal "-08:00", TimeUtil.timezone_to_hour_minute_utc_offset("\"America/Los_Angeles\""),                       "Handles quoted strings (you get these from ICS files)"
    assert_equal "-07:00", TimeUtil.timezone_to_hour_minute_utc_offset("America/Los_Angeles", Date.parse("2014-05-01")), "Handles daylight savings offset"
    Timecop.return
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