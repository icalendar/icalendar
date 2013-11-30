module Icalendar

  class Journal < Component

    required_property :dtstamp
    required_property :uid

    optional_single_property :ip_class
    optional_single_property :created
    optional_single_property :dtstart
    optional_single_property :last_mod
    optional_single_property :organizer
    optional_single_property :recurrence_id
    optional_single_property :sequence
    optional_single_property :status
    optional_single_property :summary
    optional_single_property :url

    optional_property :rrule, Icalendar::Values::Text, true
    optional_property :attach, Icalendar::Values::Uri
    optional_property :attendee
    optional_property :categories
    optional_property :comment
    optional_property :contact
    optional_property :description
    optional_property :exdate
    optional_property :rstatus
    optional_property :related
    optional_property :rdate

    def initialize
      super 'journal'
      self.dtstamp = Time.now.utc.to_datetime
      self.uid = new_uid
    end

  end

end