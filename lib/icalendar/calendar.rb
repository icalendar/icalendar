module Icalendar

  class Calendar < Component
    required_property :version
    required_property :prodid
    optional_single_property :calscale
    optional_single_property :ip_method
    optional_single_property :ip_name
    optional_single_property :description
    optional_single_property :uid
    optional_single_property :last_modified, Icalendar::Values::DateTime
    optional_single_property :url, Icalendar::Values::Uri
    optional_single_property :categories
    optional_single_property :refresh_interval, Icalendar::Values::Duration
    optional_single_property :source, Icalendar::Values::Uri
    optional_single_property :color
    optional_single_property :image, Icalendar::Values::Uri
    optional_single_property :conference, Icalendar::Values::Uri

    component :timezone, :tzid
    component :event
    component :todo
    component :journal
    component :freebusy

    def initialize
      super 'calendar'
      self.prodid = 'icalendar-ruby'
      self.version = '2.0'
      self.calscale = 'GREGORIAN'
    end

    def publish
      self.ip_method = 'PUBLISH'
    end

  end

end
