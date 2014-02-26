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
iCalendar format defined by RFC-2445:

The use of calendaring and scheduling has grown considerably in the
last decade. Enterprise and inter-enterprise business has become
dependent on rapid scheduling of events and actions using this
information technology. However, the longer term growth of calendaring
and scheduling, is currently limited by the lack of Internet standards
for the message content types that are central to these knowledgeware
applications. This memo is intended to progress the level of
interoperability possible between dissimilar calendaring and
scheduling applications. This memo defines a MIME content type for
exchanging electronic calendaring and scheduling information. The
Internet Calendaring and Scheduling Core Object Specification, or
iCalendar, allows for the capture and exchange of information normally
stored within a calendaring and scheduling application; such as a
Personal Information Manager (PIM) or a Group Scheduling product. 

The iCalendar format is suitable as an exchange format between
applications or systems. The format is defined in terms of a MIME
content type. This will enable the object to be exchanged using
several transports, including but not limited to SMTP, HTTP, a file
system, desktop interactive protocols such as the use of a memory-
based clipboard or drag/drop interactions, point-to-point asynchronous
communication, wired-network transport, or some form of unwired
transport such as infrared might also be used.


EXAMPLES
---

### Probably want to start with this ###

    require 'icalendar'
    require 'date'

    include Icalendar # You should do this in your class to limit namespace overlap

### Creating calendars and events ###

    # Create a calendar with an event (standard method)
    cal = Calendar.new
    cal.event do
      dtstart       Date.new(2005, 04, 29)
      dtend         Date.new(2005, 04, 28)
      summary     "Meeting with the man."
      description "Have a long lunch meeting and decide nothing..."
      klass       "PRIVATE"
    end

    cal.publish

#### Or you can make events like this ####

    event = Event.new
    event.start = DateTime.civil(2006, 6, 23, 8, 30)
    event.summary = "A great event!"
    cal.add_event(event)

    event2 = cal.event  # This automatically adds the event to the calendar
    event2.start = DateTime.civil(2006, 6, 24, 8, 30)
    event2.summary = "Another great event!"

#### Now with support for property parameters ####

    params = {"ALTREP" =>['"http://my.language.net"'], "LANGUAGE" => ["SPANISH"]}

    cal.event do
      dtstart Date.new(2005, 04, 29)
      dtend   Date.new(2005, 04, 28)
      summary "This is a summary with params.", params
    end

#### We can output the calendar as a string ####

    cal_string = cal.to_ical
    puts cal_string

ALARMS
---

### Within an event ###

    cal.event do
      # ...other event properties
      alarm do
        action        "EMAIL"
        description   "This is an event reminder" # email body (required)
        summary       "Alarm notification"        # email subject (required)
        attendees     %w(mailto:me@my-domain.com mailto:me-too@my-domain.com) # one or more email recipients (required)
        add_attendee  "mailto:me-three@my-domain.com"
        remove_attendee "mailto:me@my-domain.com"
        trigger       "-PT15M" # 15 minutes before
        add_attach    "ftp://host.com/novo-procs/felizano.exe", {"FMTTYPE" => "application/binary"} # email attachments (optional)
      end

      alarm do
        action        "DISPLAY" # This line isn't necessary, it's the default
        summary       "Alarm notification"
        trigger       "-P1DT0H0M0S" # 1 day before
      end

      alarm do
        action        "AUDIO"
        trigger       "-PT15M"
        add_attach    "Basso", {"VALUE" => ["URI"]}  # only one attach allowed (optional)
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

    cal = Calendar.new
    cal.timezone do
      timezone_id             "America/Chicago"

      daylight do
        timezone_offset_from  "-0600"
        timezone_offset_to    "-0500"
        timezone_name         "CDT"
        dtstart               "19700308TO20000"
        add_recurrence_rule   "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"
      end

      standard do
        timezone_offset_from  "-0500"
        timezone_offset_to    "-0600"
        timezone_name         "CST"
        dtstart               "19701101T020000"
        add_recurrence_rule   "YEARLY;BYMONTH=11;BYDAY=1SU"
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

iCalendar has some basic support for creating VTIMEZONE blocks from timezone information pulled from `tzinfo`. You must require `tzinfo` support manually to take advantage, and iCalendar only supports `tzinfo` with versions `~> 0.3`

#### Example ####

    require 'tzinfo'
    require 'icalendar/tzinfo'
    
    cal = Calendar.new
    
    event_start = DateTime.new 2008, 12, 29, 8, 0, 0
    event_end = DateTime.new 2008, 12, 29, 11, 0, 0
    
    tzid = "America/Chicago"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone event_start
    cal.add timezone
  
    cal.event do
        dtstart     event_start.tap { |d| d.ical_params = {'TZID' => tzid} }
        dtend       event_end.tap { |d| d.ical_params = {'TZID' => tzid} }
        summary     "Meeting with the man."
        description "Have a long lunch meeting and decide nothing..."
    end


Unicode
---

Add `$KCODE = 'u'` to make icalendar work correctly with Utf8 texts

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
    puts "start date-time timezone: #{event.dtstart.icalendar_tzid}" if event.dtstart.is_a?(DateTime)
    puts "summary: #{event.summary}"

    # Some calendars contain non-standard parameters (e.g. Apple iCloud
    # calendars). You can pass in a `strict` value when creating a new parser.
    unstrict_parser = Icalendar::Parser.new(cal_file, false)
    cal = unstrict_parser.parse()

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
    $ rake test

License
---

This library is released under the same license as Ruby itself.

Support & Contributions
---

Please submit pull requests from a rebased topic branch and
include tests for all bugs and features.
