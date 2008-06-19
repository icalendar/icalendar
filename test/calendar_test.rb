$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'icalendar'

require 'date'

class TestCalendar < Test::Unit::TestCase
  include Icalendar
   # Generate a calendar using the raw api, and then spit it out
   # as a string.  Parse the string and make sure everything matches up.
   def test_raw_generation    
      # Create a fresh calendar
      cal = Calendar.new

      cal.calscale = "GREGORIAN"
      cal.version = "3.2"
      cal.prodid = "test-prodid"

      # Now generate the string and then parse it so we can verify 
      # that everything was set, generated and parsed correctly.
      calString = cal.to_ical

      cals = Parser.new(calString).parse

      cal2 = cals.first
      assert_equal("GREGORIAN", cal2.calscale)
      assert_equal("3.2", cal2.version)
      assert_equal("test-prodid", cal2.prodid)
   end

   def test_block_creation
      cal = Calendar.new
      cal.event do
         self.dtend = "19970903T190000Z"
         self.summary = "This is my summary"
      end

      event = cal.event
      event.dtend "19970903T190000Z", {:TZID => "Europe/Copenhagen"}
      event.summary "This is my summary"

      ev = cal.events.each do |ev|
         assert_equal("19970903T190000Z", ev.dtend)
         assert_equal("This is my summary", ev.summary)
      end
   end

   def test_find
     cal = Calendar.new

     # add some events so we actually have to search
     10.times do 
       cal.event
       cal.todo 
       cal.journal
       cal.freebusy 
     end
     event = cal.events[5]
     assert_equal(event, cal.find_event(event.uid))

     todo = cal.todos[5]
     assert_equal(todo, cal.find_todo(todo.uid))

     journal = cal.journals[5]
     assert_equal(journal, cal.find_journal(journal.uid))
     
     freebusy = cal.freebusys[5]
     assert_equal(freebusy, cal.find_freebusy(freebusy.uid))
   end
end
