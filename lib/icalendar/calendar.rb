=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Icalendar

  class Calendar < Component
    ical_component :timezones, :events, :todos, :journals, :freebusys

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

    def print_headers
      "VERSION:#{version}\r\n"
    end

    def properties_to_print
      @properties.select { |k,v| k != 'version' }
    end

    def event(&block)
      calendar_tzid = timezone_id
      build_component Event.new do
        # Note: I'm not sure this is the best way to pass this down, but it works
        self.tzid = calendar_tzid

        if block
          instance_eval(&block)
          if tzid
            dtstart.ical_params = { "TZID" => tzid }
            dtend.ical_params = { "TZID" => tzid } unless dtend.nil?
          end
        end
      end
    end

    def find_event(uid)
      events.find {|e| e.uid == uid}
    end

    def todo(&block)
      build_component Todo.new, &block
    end

    def find_todo(uid)
      todos.find {|t| t.uid == uid}
    end

    def journal(&block)
      build_component Journal.new, &block
    end

    def find_journal(uid)
      journals.find {|j| j.uid == uid}
    end

    def freebusy(&block)
      build_component Freebusy.new, &block
    end

    def find_freebusy(uid)
      freebusys.find {|f| f.uid == uid}
    end

    def timezone(&block)
      build_component Timezone.new, &block
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

    private

      def build_component(component, &block)
        add_component component
        component.instance_eval(&block) if block
        component
      end

      def timezone_id
        timezones[0].tzid if timezones.length > 0
      end
  end # class Calendar

end # module Icalendar
