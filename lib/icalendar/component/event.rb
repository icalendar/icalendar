=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Icalendar
  # A Event calendar component is a grouping of component
  # properties, and possibly including Alarm calendar components, that
  # represents a scheduled amount of time on a calendar. For example, it
  # can be an activity; such as a one-hour long, department meeting from
  # 8:00 AM to 9:00 AM, tomorrow. Generally, an event will take up time
  # on an individual calendar.
  class Event < Component
    ical_component :alarms

    ## Single instance properties

    # Access classification (PUBLIC, PRIVATE, CONFIDENTIAL...)
    ical_property :ip_class, :klass

    ical_property :ip_name

    # Date & time of creation
    ical_property :created

    # Complete description of the calendar component
    ical_property :description

    # Specifies the timezone for the event
    attr_accessor :tzid

    # Specifies date-time when calendar component begins
    ical_property :dtstart, :start

    # Latitude & longitude for specified activity
    ical_property :geo, :geo_location

    # Date & time this item was last modified
    ical_property :last_modified

    # Specifies the intended venue for this activity
    ical_property :location

    # Defines organizer of this item
    ical_property :organizer

    # Defines relative priority for this item (1-9... 1 = best)
    ical_property :priority

    # Indicate date & time when this item was created
    ical_property :dtstamp, :timestamp

    # Revision sequence number for this item
    ical_property :sequence, :seq

    # Defines overall status or confirmation of this item
    ical_property :status
    ical_property :summary
    ical_property :transp, :transparency

    # Defines a persistent, globally unique id for this item
    ical_property :uid, :unique_id

    # Defines a URL associated with this item
    ical_property :url
    ical_property :recurrence_id, :recurid

    ## Single but mutually exclusive properties (Not testing though)

    # Specifies a date and time that this item ends
    ical_property :dtend, :end

    # Specifies a positive duration time
    ical_property :duration

    ## Multi-instance properties

    # Associates a URI or binary blob with this item
    ical_multiline_property :attach, :attachment, :attachments

    # Defines an attendee for this calendar item
    ical_multiline_property :attendee, :attendee, :attendees

    # Defines the categories for a calendar component (school, work...)
    ical_multi_property :categories, :category, :categories

    # Simple comment for the calendar user.
    ical_multi_property :comment, :comment, :comments

    # Contact information associated with this item.
    ical_multi_property :contact, :contact, :contacts
    ical_multi_property :exdate, :exception_date, :exception_dates
    ical_multi_property :exrule, :exception_rule, :exception_rules
    ical_multi_property :rstatus, :request_status, :request_statuses

    # Used to represent a relationship between two calendar items
    ical_multi_property :related_to, :related_to, :related_tos
    ical_multi_property :resources, :resource, :resources

    # Used with the UID & SEQUENCE to identify a specific instance of a
    # recurring calendar item.
    ical_multi_property :rdate, :recurrence_date, :recurrence_dates
    ical_multi_property :rrule, :recurrence_rule, :recurrence_rules

    def initialize()
      super("VEVENT")

      # Now doing some basic initialization
      sequence 0
      timestamp Time.now.utc.to_datetime.tap { |t| t.icalendar_tzid = 'UTC' }
      uid new_uid
    end

    def alarm(&block)
      a = Alarm.new
      self.add a

      a.instance_eval(&block) if block

      a
    end

    def occurrences_starting(time)
      recurrence_rules.first.occurrences_of_event_starting(self, time)
    end

  end
end
