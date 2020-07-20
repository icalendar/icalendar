module Icalendar

  class Calendar < Component
    required_property :version
    required_property :prodid
    optional_single_property :calscale
    optional_single_property :ip_method
    optional_single_property :x_wr_calname
    optional_single_property :x_wr_timezone

    component :timezone, :tzid
    component :event
    component :todo
    component :journal
    component :freebusy

    def initialize(name = nil, timezone = nil)
      super 'calendar'
      self.prodid = 'icalendar-ruby'
      self.version = '2.0'
      self.calscale = 'GREGORIAN'
      self.x_wr_calname = name if name
      self.x_wr_timezone = timezone if timezone
    end

    def publish
      self.ip_method = 'PUBLISH'
    end

  end

end
