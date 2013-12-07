require File.dirname(__FILE__) + '/test_helper.rb'

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

      cal.events.each do |ev|
         assert_equal("19970903T190000Z", ev.dtend)
         assert_equal("This is my summary", ev.summary)
      end
   end

   def test_create_multiple_event_calendar
       # Create a fresh calendar
       cal = Calendar.new
       [1,2,3].each do |t|
           cal.event do
               self.dtend = "1997090#{t}T190000Z"
               self.summary = "This is summary #{t}"
           end
       end
       [1,2,3].each do |t|
           cal.todo do
               self.summary = "test #{t} todo"
           end
       end
       cal.to_ical
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

   def test_set_and_get_proprietary_attributes
     cal = Calendar.new

     cal.x_wr_name = 'Icalendar Calendar'

     calString = cal.to_ical

     cals = Parser.new(calString).parse

     cal2 = cals.first
     assert_equal(["Icalendar Calendar"], cal2.x_wr_name)
   end

   def test_respond_to_proprietary_attributes
     cal = Calendar.new

     assert_respond_to(cal, 'x_wr_name=')
   end
end
