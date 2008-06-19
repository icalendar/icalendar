=begin
  Copyright (C) 2005 Jeff Rose
  Copyright (C) 2005 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'date'
require 'uri'
require 'stringio'

module Icalendar
  def Icalendar.parse(src, single = false)
    cals = Icalendar::Parser.new(src).parse

    if single
      cals.first
    else
      cals
    end
  end

  class Parser < Icalendar::Base
    # date = date-fullyear ["-"] date-month ["-"] date-mday
    # date-fullyear = 4 DIGIT
    # date-month = 2 DIGIT
    # date-mday = 2 DIGIT
    DATE = '(\d\d\d\d)-?(\d\d)-?(\d\d)'

    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour = 2 DIGIT
    # time-minute = 2 DIGIT
    # time-second = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone = "Z" / time-numzone
    # time-numzome = sign time-hour [":"] time-minute
    TIME = '(\d\d):?(\d\d):?(\d\d)(\.\d+)?(Z|[-+]\d\d:?\d\d)?'

    def initialize(src)
      # Setup the parser method hash table
      setup_parsers()

      if src.respond_to?(:gets)
        @file = src
      elsif (not src.nil?) and src.respond_to?(:to_s)
        @file = StringIO.new(src.to_s, 'r')
      else
        raise ArgumentError, "CalendarParser.new cannot be called with a #{src.class} type!"
      end

      @prev_line = @file.gets
      @prev_line.chomp! unless @prev_line.nil?

      @@logger.debug("New Calendar Parser: #{@file.inspect}")
    end

    # Define next line for an IO object.
    # Works for strings now with StringIO
    def next_line
      line = @prev_line

      if line.nil? 
        return nil 
      end

      # Loop through until we get to a non-continuation line...
      loop do
        nextLine = @file.gets
        @@logger.debug "new_line: #{nextLine}"

        if !nextLine.nil?
          nextLine.chomp!
        end

        # If it's a continuation line, add it to the last.
        # If it's an empty line, drop it from the input.
        if( nextLine =~ /^[ \t]/ )
          line << nextLine[1, nextLine.size]
        elsif( nextLine =~ /^$/ )
        else
          @prev_line = nextLine
          break
        end
      end
      line
    end

    # Parse the calendar into an object representation
    def parse
      calendars = []

      @@logger.debug "parsing..."
      # Outer loop for Calendar objects
      while (line = next_line) 
        fields = parse_line(line)

        # Just iterate through until we find the beginning of a calendar object
        if fields[:name] == "BEGIN" and fields[:value] == "VCALENDAR"
          cal = parse_component
          @@logger.debug "Added parsed calendar..."
          calendars << cal
        end
      end

      calendars
    end

    private

    # Parse a single VCALENDAR object
    # -- This should consist of the PRODID, VERSION, option METHOD & CALSCALE,
    # and then one or more calendar components: VEVENT, VTODO, VJOURNAL, 
    # VFREEBUSY, VTIMEZONE
    def parse_component(component = Calendar.new)
      @@logger.debug "parsing new component..."

      while (line = next_line)
        fields = parse_line(line)

        name = fields[:name].upcase

        # Although properties are supposed to come before components, we should
        # be able to handle them in any order...
        if name == "END"
          break
        elsif name == "BEGIN" # New component
          case(fields[:value])
          when "VEVENT" # Event
            component.add_component parse_component(Event.new)
          when "VTODO" # Todo entry
            component.add_component parse_component(Todo.new)
          when "VALARM" # Alarm sub-component for event and todo
            component.add_component parse_component(Alarm.new)
          when "VJOURNAL" # Journal entry
            component.add_component parse_component(Journal.new)
          when "VFREEBUSY" # Free/Busy section
            component.add_component parse_component(Freebusy.new)
          when "VTIMEZONE" # Timezone specification
            component.add_component parse_component(Timezone.new)
          when "STANDARD" # Standard time sub-component for timezone
            component.add_component parse_component(Standard.new)
          when "DAYLIGHT" # Daylight time sub-component for timezone
            component.add_component parse_component(Daylight.new)
          else # Uknown component type, skip to matching end
            until ((line = next_line) == "END:#{fields[:value]}"); end
            next
          end
        else # If its not a component then it should be a property
          params = fields[:params]
          value = fields[:value]

          # Lookup the property name to see if we have a string to
          # object parser for this property type.
          if @parsers.has_key?(name)
            value = @parsers[name].call(name, params, value)
          end

          name = name.downcase

          # TODO: check to see if there are any more conflicts.
          if name == 'class' or name == 'method'
            name = "ip_" + name
          end

          # Replace dashes with underscores
          name = name.gsub('-', '_')

          if component.multi_property?(name)
            adder = "add_" + name
            if component.respond_to?(adder)
              component.send(adder, value, params)
            else
              raise(UnknownPropertyMethod, "Unknown property type: #{adder}")
            end
          else
            if component.respond_to?(name)
              component.send(name, value, params)
            else
              raise(UnknownPropertyMethod, "Unknown property type: #{name}")
            end
          end
        end  
      end

      component
    end

    # 1*(ALPHA / DIGIT / "=")
    NAME    = '[-a-z0-9]+'

    # <"> <Any character except CTLs, DQUOTE> <">
    QSTR    = '"[^"]*"'

    # Contentline
    LINE = "(#{NAME})(.*(?:#{QSTR})|(?:[^:]*))\:(.*)"
   
    # *<Any character except CTLs, DQUOTE, ";", ":", ",">
    PTEXT   = '[^";:,]*'

    # param-value = ptext / quoted-string
    PVALUE  = "#{QSTR}|#{PTEXT}"

    # param = name "=" param-value *("," param-value)
    PARAM = ";(#{NAME})(=?)((?:#{PVALUE})(?:,#{PVALUE})*)"

    def parse_line(line)
      unless line =~ %r{#{LINE}}i # Case insensitive match for a valid line
        raise "Invalid line in calendar string!"
      end

      name = $1.upcase # The case insensitive part is upcased for easier comparison...
      paramslist = $2
      value = $3.gsub("\\;", ";").gsub("\\,", ",").gsub("\\n", "\n").gsub("\\\\", "\\")

      # Parse the parameters
      params = {}
      if paramslist.size > 1
        paramslist.scan( %r{#{PARAM}}i ) do

        # parameter names are case-insensitive, and multi-valued
        pname = $1
        pvals = $3

        # If their isn't an '=' sign then we need to do some custom
        # business.  Defaults to 'type'
        if $2 == ""
          pvals = $1
          case $1
          when /quoted-printable/i
            pname = 'encoding'

          when /base64/i
            pname = 'encoding'

          else
            pname = 'type'
          end
        end

        # Make entries into the params dictionary where the name
        # is the key and the value is an array of values.
        unless params.key? pname
          params[pname] = []
        end

        # Save all the values into the array.
        pvals.scan( %r{(#{PVALUE})} ) do
          if $1.size > 0
            params[pname] << $1
          end
        end
        end
      end

      {:name => name, :value => value, :params => params}
    end

    ## Following is a collection of parsing functions for various 
    ## icalendar property value data types...  First we setup
    ## a hash with property names pointing to methods...
    def setup_parsers
      @parsers = {}

      # Integer properties
      m = self.method(:parse_integer)
      @parsers["PERCENT-COMPLETE"] = m
      @parsers["PRIORITY"] = m
      @parsers["REPEAT"] = m
      @parsers["SEQUENCE"] = m

      # Dates and Times
      m = self.method(:parse_datetime)
      @parsers["COMPLETED"] = m
      @parsers["DTEND"] = m
      @parsers["DUE"] = m
      @parsers["DTSTART"] = m
      @parsers["RECURRENCE-ID"] = m
      @parsers["EXDATE"] = m
      @parsers["RDATE"] = m
      @parsers["CREATED"] = m
      @parsers["DTSTAMP"] = m
      @parsers["LAST-MODIFIED"] = m

      # URI's
      m = self.method(:parse_uri)
      @parsers["TZURL"] = m
      @parsers["ATTENDEE"] = m
      @parsers["ORGANIZER"] = m
      @parsers["URL"] = m

      # This is a URI by default, and if its not a valid URI
      # it will be returned as a string which works for binary data
      # the other possible type.
      @parsers["ATTACH"] = m 

      # GEO
      m = self.method(:parse_geo)
      @parsers["GEO"] = m

    end

    # Booleans
    # NOTE: It appears that although this is a valid data type
    # there aren't any properties that use it...  Maybe get
    # rid of this in the future.
    def parse_boolean(name, params, value)
      if value.upcase == "FALSE"
        false
      else
        true
      end
    end

    # Dates, Date-Times & Times
    # NOTE: invalid dates & times will be returned as strings...
    def parse_datetime(name, params, value)
      begin
        DateTime.parse(value)
      rescue Exception
        value
      end

    end

    # Durations
    # TODO: Need to figure out the best way to represent durations 
    # so just returning string for now.
    def parse_duration(name, params, value)
      value
    end

    # Floats
    # NOTE: returns 0.0 if it can't parse the value
    def parse_float(name, params, value)
      value.to_f
    end

    # Integers
    # NOTE: returns 0 if it can't parse the value
    def parse_integer(name, params, value)
      value.to_i
    end

    # Periods
    # TODO: Got to figure out how to represent periods also...
    def parse_period(name, params, value)
      value
    end

    # Calendar Address's & URI's
    # NOTE: invalid URI's will be returned as strings...
    def parse_uri(name, params, value)
      begin
        URI.parse(value)
      rescue Exception
        value
      end
    end

    # Geographical location (GEO)
    # NOTE: returns an array with two floats (long & lat)
    # if the parsing fails return the string
    def parse_geo(name, params, value)
      strloc = value.split(';')
      if strloc.size != 2 
        return value
      end

      Geo.new(strloc[0].to_f, strloc[1].to_f)
    end

  end
end
