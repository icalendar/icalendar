=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Icalendar

  class Calendar < Component
    ical_component :events, :todos, :journals, :freebusys, :timezones

    ical_property :calscale, :calendar_scale
    ical_property :prodid, :product_id
    ical_property :version
    ical_property :ip_method

    def initialize()
      super("VCALENDAR")

      # Set some defaults
      self.calscale = "GREGORIAN"    # Who knows, but this is the only one in the spec.
      self.prodid = "iCalendar-Ruby" # Current product... Should be overwritten by apps that use the library
      self.version = "2.0" # Version of the specification
    end

    def event(&block)
      e = Event.new
      self.add_component e

      e.instance_eval &block if block

      e
    end
    
    def find_event(uid)
      self.events.find {|e| e.uid == uid}
    end

    def todo(&block)
      e = Todo.new
      self.add_component e

      e.instance_eval &block if block

      e
    end

    def find_todo(uid)
      self.todos.find {|t| t.uid == uid}
    end
    
    def journal(&block)
      e = Journal.new
      self.add_component e

      e.instance_eval &block if block

      e
    end

    def find_journal(uid)
      self.journals.find {|j| j.uid == uid}
    end

    def freebusy(&block)
      e = Freebusy.new
      self.add_component e

      e.instance_eval &block if block

      e
    end

    def find_freebusy(uid)
      self.freebusys.find {|f| f.uid == uid}
    end

    def timezone(&block)
      e = Timezone.new
      self.add_component e

      e.instance_eval &block if block

      e
    end
    
    # The "PUBLISH" method in a "VEVENT" calendar component is an
    # unsolicited posting of an iCalendar object. Any CU may add published
    # components to their calendar. The "Organizer" MUST be present in a
    # published iCalendar component. "Attendees" MUST NOT be present. Its
    # expected usage is for encapsulating an arbitrary event as an
    # iCalendar object. The "Organizer" may subsequently update (with
    # another "PUBLISH" method), add instances to (with an "ADD" method),
    # or cancel (with a "CANCEL" method) a previously published "VEVENT"
    # calendar component.
    def publish
      self.ip_method = "PUBLISH"
    end

  end # class Calendar

end # module Icalendar
