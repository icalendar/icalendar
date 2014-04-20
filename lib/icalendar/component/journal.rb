=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end
module Icalendar
  # A Journal calendar component is a grouping of
  # component properties that represent one or more descriptive text
  # notes associated with a particular calendar date. The "DTSTART"
  # property is used to specify the calendar date that the journal entry
  # is associated with. Generally, it will have a DATE value data type,
  # but it can also be used to specify a DATE-TIME value data type.
  # Examples of a journal entry include a daily record of a legislative
  # body or a journal entry of individual telephone contacts for the day
  # or an ordered list of accomplishments for the day. The Journal
  # calendar component can also be used to associate a document with a
  # calendar date.
  class Journal < Component

    # Single properties
    ical_property :ip_class
    ical_property :created
    ical_property :description
    ical_property :dtstart, :start
    ical_property :last_modified
    ical_property :organizer
    ical_property :dtstamp, :timestamp
    ical_property :sequence, :seq
    ical_property :status
    ical_property :summary
    ical_property :uid, :user_id
    ical_property :url
    ical_property :recurid, :recurrence_id

    # Multi-properties
    ical_multiline_property :attach, :attachment, :attachments
    ical_multiline_property :attendee, :attendee, :attendees
    ical_multi_property :categories, :category, :categories
    ical_multi_property :comment, :comment, :comments
    ical_multi_property :contact, :contact, :contacts
    ical_multi_property :exdate, :exception_date, :exception_dates
    ical_multi_property :exrule, :exception_rule, :exception_rules
    ical_multi_property :rstatus, :request_status, :request_statuses
    ical_multi_property :related_to, :related_to, :related_tos
    ical_multi_property :resources, :resource, :resources
    ical_multi_property :rdate, :recurrence_date, :recurrence_dates
    ical_multi_property :rrule, :recurrence_rule, :recurrence_rules

    def initialize()
      super("VJOURNAL")

      sequence 0
      timestamp Time.now.utc.to_datetime.tap { |t| t.icalendar_tzid = 'UTC' }
      uid new_uid
    end

  end
end
