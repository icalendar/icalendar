module Icalendar

  class Freebusy < Component

    required_property :dtstamp
    required_property :uid

    optional_single_property :contact
    optional_single_property :dtstart
    optional_single_property :dtend
    optional_single_property :organizer
    optional_single_property :url

    optional_property :attendee
    optional_property :comment
    optional_property :freebusy
    optional_property :rstatus

    def initialize
      super 'freebusy'
      self.dtstamp = Time.now.utc.to_datetime
      self.uid = new_uid
    end

  end

end