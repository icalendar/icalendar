module Icalendar

  class Calendar < Component
    required_property :version
    required_property :prodid
    optional_single_property :calscale
    optional_single_property :ip_method
    optional_property :ip_name
    optional_property :description
    optional_single_property :uid
    optional_single_property :last_modified, Icalendar::Values::DateTime, true
    optional_single_property :url, Icalendar::Values::Uri, true
    optional_property :categories
    optional_single_property :refresh_interval, Icalendar::Values::Duration, true
    optional_single_property :source, Icalendar::Values::Uri, true
    optional_single_property :color
    optional_property :image, Icalendar::Values::Uri, false, true

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
