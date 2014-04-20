$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'icalendar'

# This is a test class for the calendar parser.  
class TestIcalendarParser < Test::Unit::TestCase

  TEST_CAL = File.join(File.dirname(__FILE__), 'fixtures', 'single_event.ics')
  NONSTANDARD = File.join(File.dirname(__FILE__), 'fixtures', 'nonstandard.ics')

  # First make sure that we can run the parser and get back objects.
  def test_new
    # Make sure we don't take invalid object types.
    assert_raise(ArgumentError) { Icalendar::Parser.new(nil) }

    # Make sure we get an object back from parsing a file
    calFile = File.open(TEST_CAL)
    cals = Icalendar::Parser.new(calFile).parse
    assert(cals)
    calFile.close

    # Make sure we get an object back from parsing a string
    calString = File.open(TEST_CAL).read
    cals = Icalendar::Parser.new(calString).parse
    assert(cals)
  end

  # Now go through and make sure the object is correct using the
  # dynamically generated raw interfaces.
  def test_zzfile_parse
    calFile = File.open(TEST_CAL)
    cals = Icalendar.parse(calFile)
    calFile.close
    do_asserts(cals)

    Icalendar::Base.quiet
  end
  
  def test_string_parse
    # Make sure we get an object back from parsing a string
    calString = File.open(TEST_CAL).read
    cals = Icalendar::Parser.new(calString).parse
    do_asserts(cals)
  end

  def test_strict_parser
    File.open(NONSTANDARD) do |cal_file|
      assert_raise(Icalendar::UnknownPropertyMethod) do
        Icalendar::Parser.new(cal_file).parse
      end
    end
  end

  def test_lenient_parser
    File.open(NONSTANDARD) do |cal_file|
      do_asserts Icalendar::Parser.new(cal_file, false).parse
    end
  end

  # Just a helper method so we don't have to repeat the same tests.
  def do_asserts(cals)
    # Should just get one calendar back.
    assert_equal(1, cals.size)
    
    cal = cals.first
    
    # Calendar properties
    assert_equal("2.0", cal.version)
    assert_equal("bsprodidfortestabc123", cal.prodid)
    
    # Now the event
    assert_equal(1, cal.events.size)
    
    event = cal.events.first
    assert_equal("bsuidfortestabc123", event.uid)
    assert_equal("SomeName", event.ip_name)
    
    summary = "This is a really long summary to test the method of unfolding lines, so I'm just going to make it a whole bunch of lines."

    assert_equal(summary, event.summary)

    start = DateTime.parse("20050120T170000")
    daend = DateTime.parse("20050120T184500")
    stamp = DateTime.parse("20050118T211523Z")
    assert_equal(start, event.dtstart)
    assert_equal(daend, event.dtend)
    assert_equal(stamp, event.dtstamp)

    organizer = URI.parse("mailto:joebob@random.net")
    assert_equal(organizer, event.organizer)

    ats = event.attachments
    assert_equal(2, ats.size)
    attachment = URI.parse("http://bush.sucks.org/impeach/him.rhtml")
    assert_equal(attachment, ats[0])
    attachment = URI.parse("http://corporations-dominate.existence.net/why.rhtml")
    assert_equal(attachment, ats[1])
  end
end
