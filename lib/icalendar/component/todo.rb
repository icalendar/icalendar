=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end
module Icalendar
  # A Todo calendar component is a grouping of component
  # properties and possibly Alarm calendar components that represent
  # an action-item or assignment. For example, it can be used to
  # represent an item of work assigned to an individual; such as "turn in
  # travel expense today".
  class Todo < Component
    ical_component :alarms

    # Single properties
    ical_property :ip_class
    ical_property :completed
    ical_property :created
    ical_property :description
    ical_property :dtstamp, :timestamp
    ical_property :dtstart, :start
    ical_property :geo
    ical_property :last_modified
    ical_property :location
    ical_property :organizer
    ical_property :percent_complete, :percent
    ical_property :priority
    ical_property :recurid, :recurrence_id
    ical_property :sequence, :seq
    ical_property :status
    ical_property :summary
    ical_property :uid, :user_id
    ical_property :url

    # Single but mutually exclusive TODO: not testing anything yet
    ical_property :due
    ical_property :duration

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
      super("VTODO")

      sequence 0
      timestamp Time.now.utc.to_datetime.tap { |t| t.icalendar_tzid = 'UTC' }
      uid new_uid
    end

  end
end
