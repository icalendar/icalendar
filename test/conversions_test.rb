$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'icalendar'

require 'date'

class TestConversions < Test::Unit::TestCase
  include Icalendar

  RESULT = <<EOS
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:iCalendar-Ruby
BEGIN:VEVENT
LAST-MODIFIED:19960817T133000
SEQUENCE:2
ORGANIZER:mailto:joe@example.com?subject=Ruby
UID:foobar
X-TIME-OF-DAY:111736
CATEGORIES:foo\\,bar\\,baz
GEO:46.01\\;8.57
DESCRIPTION:desc
DTSTART:20060720
DTSTAMP:20060720T174052
END:VEVENT
END:VCALENDAR
EOS

  def setup
    @cal = Calendar.new
  end

  def test_to_ical_conversions
    @cal.event do 
      # String
      description "desc"

      # Fixnum
      sequence 2

      # Float by way of Geo class
      geo(Geo.new(46.01, 8.57))
      
      # Array
      categories ["foo", "bar"]
      add_category "baz"

      # Last Modified 
      last_modified DateTime.parse("1996-08-17T13:30:00")

      # URI
      organizer(URI::MailTo.build(['joe@example.com', 'subject=Ruby']))
      
      # Date
      start  Date.parse("2006-07-20")

      # DateTime
      timestamp DateTime.parse("2006-07-20T17:40:52+0200")

      # Time
      x_time_of_day Time.at(123456)

      uid "foobar"
    end
       
    assert_equal(RESULT.gsub("\n", "\r\n"), @cal.to_ical)
  end

  def test_to_ical_folding
    @cal.x_wr_calname = 'Test Long Description'
    
    @cal.event do
      url      'http://test.com/events/644'
      dtend     DateTime.parse('20061215T180000')
      dtstart   DateTime.parse('20061215T160000')
      timestamp DateTime.parse('20061215T114034')
      seq       1001
      uid      'foobar'
      summary  'DigiWorld 2006'

      description "FULL DETAILS:\nhttp://test.com/events/570\n\n" + 
        "Cary Brothers walks the same musical ground as Pete Yorn, Nick Drake, " + 
        "Jeff Buckley and others; crafting emotional melodies, with strong vocals " + 
        "and thoughtful lyrics. Brett Dennen has &quot;that thing.&quot; " + 
        "Inspired fans describe it: &quot;lush shimmering vocals, an intricately " + 
        "groovin&#39; guitar style, a lyrical beauty rare in a young songwriter," + 
        "&quot; and &quot;this soulful blend of everything that feels good.&quot; " + 
        "Rising up around him is music; transcending genres, genders and generations."
    end
    
    folded = File.read(File.join(File.dirname(__FILE__), 'fixtures/folding.ics')).gsub("\n", "\r\n")
    assert_equal(folded, @cal.to_ical)
  end
  
end
