=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end
module Icalendar
  # A Freebusy calendar component is a grouping of
  # component properties that represents either a request for, a reply to
  # a request for free or busy time information or a published set of
  # busy time information.
  class Freebusy < Component
    # Single properties
    ical_property :contact
    ical_property :dtstart, :start
    ical_property :dtend, :end
    ical_property :dtstamp, :timestamp
    ical_property :duration
    ical_property :organizer
    ical_property :uid, :user_id
    ical_property :url
    ical_property :summary

    # Multi-properties
    ical_multiline_property :attendee, :attendee, :attendees
    ical_multi_property :comment, :comment, :comments
    ical_multiline_property :freebusy, :freebusy, :freebusys
    ical_multi_property :rstatus, :request_status, :request_statuses

    def initialize()
      super("VFREEBUSY")

      timestamp Time.now.utc.to_datetime.tap { |t| t.icalendar_tzid = 'UTC' }
      uid new_uid
    end
  end
end
