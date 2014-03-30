iCalendar -- Internet calendaring, Ruby style
===

[![Build Status](https://travis-ci.org/icalendar/icalendar.png)](https://travis-ci.org/icalendar/icalendar)
[![Code Climate](https://codeclimate.com/github/icalendar/icalendar.png)](https://codeclimate.com/github/icalendar/icalendar)

<http://github.com/icalendar/icalendar>

2.x Status
---

iCalendar 2.0 is under active development, and can be followed in the
[2.0beta branch](https://github.com/icalendar/icalendar/tree/2.0beta).

iCalendar 1.x (currently the master branch) will still survive for a
while, but will only be accepting bug fixes from this point forward
unless someone else wants to take over more active maintainership of
the 1.x series.

### 2.0 Goals ###

* Implements [RFC 5545](http://tools.ietf.org/html/rfc5545)
* More obvious access to parameters and values
* Cleaner & easier timezone support


DESCRIPTION
---

iCalendar is a Ruby library for dealing with iCalendar files in the
iCalendar format defined by [RFC-5545](http://tools.ietf.org/html/rfc5545).

EXAMPLES
---

### Creating calendars and events ###

    require 'icalendar'

    # Create a calendar with an event (standard method)
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = Icalendar::Values::Date.new('20050428')
      e.dtend       = Icalendar::Values::Date.new('20050429')
      e.summary     = "Meeting with the man."
      e.description = "Have a long lunch meeting and decide nothing..."
      e.ip_class    = "PRIVATE"
    end

    cal.publish

#### Or you can make events like this ####

    event = Icalendar::Event.new
    event.dtstart = DateTime.civil(2006, 6, 23, 8, 30)
    event.summary = "A great event!"
    cal.add_event(event)

    event2 = cal.event  # This automatically adds the event to the calendar
    event2.dtstart = DateTime.civil(2006, 6, 24, 8, 30)
    event2.summary = "Another great event!"

#### Support for property parameters ####

    params = {"altrep" => "http://my.language.net", "language" => "SPANISH"}

    cal.event do |e|
      e.dtstart = Icalendar::Values::Date.new('20050428')
      e.dtend   = Icalendar::Values::Date.new('20050429')
      e.summary = Icalendar::Values::Text.new "This is a summary with params.", params
    end

    # or

    cal.event do |e|
      e.dtstart = Icalendar::Values::Date.new('20050428')
      e.dtend   = Icalendar::Values::Date.new('20050429')
      e.summary = "This is a summary with params."
      e.summary.ical_params = params
    end

#### We can output the calendar as a string ####

    cal_string = cal.to_ical
    puts cal_string

ALARMS
---

### Within an event ###

    cal.event do |e|
      # ...other event properties
      e.alarm do |a|
        a.action          = "EMAIL"
        a.description     = "This is an event reminder" # email body (required)
        a.summary         = "Alarm notification"        # email subject (required)
        a.attendee        = %w(mailto:me@my-domain.com mailto:me-too@my-domain.com) # one or more email recipients (required)
        a.append_attendee "mailto:me-three@my-domain.com"
        a.trigger         = "-PT15M" # 15 minutes before
        a.append_attach   Icalendar::Values::Uri.new "ftp://host.com/novo-procs/felizano.exe", "fmttype" => "application/binary" # email attachments (optional)
      end

      e.alarm do |a|
        a.action  = "DISPLAY" # This line isn't necessary, it's the default
        a.summary = "Alarm notification"
        a.trigger = "-P1DT0H0M0S" # 1 day before
      end

      e.alarm do |a|
        a.action        = "AUDIO"
        a.trigger       = "-PT15M"
        a.append_attach "Basso"
      end
    end

#### Output ####

    # BEGIN:VALARM
    # ACTION:EMAIL
    # ATTACH;FMTTYPE=application/binary:ftp://host.com/novo-procs/felizano.exe
    # TRIGGER:-PT15M
    # SUMMARY:Alarm notification
    # DESCRIPTION:This is an event reminder
    # ATTENDEE:mailto:me-too@my-domain.com
    # ATTENDEE:mailto:me-three@my-domain.com
    # END:VALARM
    #
    # BEGIN:VALARM
    # ACTION:DISPLAY
    # TRIGGER:-P1DT0H0M0S
    # SUMMARY:Alarm notification
    # END:VALARM
    #
    # BEGIN:VALARM
    # ACTION:AUDIO
    # ATTACH;VALUE=URI:Basso
    # TRIGGER:-PT15M
    # END:VALARM


TIMEZONES
---

    cal = Icalendar::Calendar.new
    cal.timezone do |t|
      t.tzid = "America/Chicago"

      t.daylight do |d|
        d.tzoffsetfrom = "-0600"
        d.tzoffsetto   = "-0500"
        d.tzname       = "CDT"
        d.dtstart      = "19700308T020000"
        d.rrule        = "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"
      end

      t.standard do |s|
        s.tzoffsetfrom = "-0500"
        s.tzoffsetto   = "-0600"
        s.tzname       = "CST"
        s.dtstart      = "19701101T020000"
        s.rrule        = "FREQ=YEARLY;BYMONTH=11;BYDAY=1SU"
      end
    end

#### Output ####

    # BEGIN:VTIMEZONE
    # TZID:America/Chicago
    # BEGIN:DAYLIGHT
    # TZOFFSETFROM:-0600
    # TZOFFSETTO:-0500
    # TZNAME:CDT
    # DTSTART:19700308T020000
    # RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
    # END:DAYLIGHT
    # BEGIN:STANDARD
    # TZOFFSETFROM:-0500
    # TZOFFSETTO:-0600
    # TZNAME:CST
    # DTSTART:19701101T020000
    # RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
    # END:STANDARD
    # END:VTIMEZONE

iCalendar has some basic support for creating VTIMEZONE blocks from timezone information pulled from `tzinfo`.
You must require `tzinfo` support manually to take advantage, and iCalendar only supports `tzinfo` with versions `~> 0.3`

#### Example ####

    require 'icalendar/tzinfo'

    cal = Icalendar::Calendar.new

    event_start = DateTime.new 2008, 12, 29, 8, 0, 0
    event_end = DateTime.new 2008, 12, 29, 11, 0, 0

    tzid = "America/Chicago"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone event_start
    cal.add_timezone timezone

    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new event_start, 'tzid' => tzid
      e.dtend   = Icalendar::Values::DateTime.new event_end, 'tzid' => tzid
      e.summary = "Meeting with the man."
      e.description = "Have a long lunch meeting and decide nothing..."
    end


Parsing iCalendars
---

    # Open a file or pass a string to the parser
    cal_file = File.open("single_event.ics")

    # Parser returns an array of calendars because a single file
    # can have multiple calendars.
    cals = Icalendar.parse(cal_file)
    cal = cals.first

    # Now you can access the cal object in just the same way I created it
    event = cal.events.first

    puts "start date-time: #{event.dtstart}"
    puts "start date-time timezone: #{event.dtstart.ical_params['tzid']}"
    puts "summary: #{event.summary}"

    # Some calendars contain non-standard parameters (e.g. Apple iCloud
    # calendars). You can pass in a `strict` value when creating a new parser.
    unstrict_parser = Icalendar::Parser.new(cal_file, false)
    cal = unstrict_parser.parse

Finders
---

Often times in web apps and other interactive applications you'll need to
lookup items in a calendar to make changes or get details.  Now you can find
everything by the unique id automatically associated with all components.

    cal = Calendar.new
    10.times { cal.event } # Create 10 events with only default data.
    some_event = cal.events[5] # Grab it from the array of events

    # Use the uid as the key in your app
    key = some_event.uid

    # so later you can find it.
    same_event = cal.find_event(key)

Examples
---

Check the unit tests for examples of most things you'll want to do, but please
send me example code or let me know what's missing.

Download
---

The latest release version of this library can be found at

* <http://rubygems.org/gems/icalendar>

Installation
---

It's all about rubygems:

    $ gem install icalendar

Testing
---

To run the tests:

    $ bundle install
    $ rake spec

License
---

This library is released under the same license as Ruby itself.


Support & Contributions
---

Please submit pull requests from a rebased topic branch and
include tests for all bugs and features.
