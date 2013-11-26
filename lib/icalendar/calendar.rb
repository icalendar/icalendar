module Icalendar

  class Calendar < Component
    required_property :prodid
    required_property :version
    optional_single_property :calscale
    optional_single_property :ip_method

    component :event
    component :todo
    component :journal
    component :freebusy
    component :timezone, :tzid

    def initialize
      super 'calendar'
      self.prodid = 'icalendar-ruby'
      self.version = '2.0'
    end

  end

end
