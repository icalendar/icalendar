=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Icalendar
  require 'socket'

  MAX_LINE_LENGTH = 75

  class Geo < Icalendar::Base
    attr_accessor :latitude, :longitude
    alias :lat :latitude
    alias :lat= :latitude=
    alias :long :longitude
    alias :long= :longitude=

    def initialize(lat, long)
      @latitude = lat
      @longitude = long
    end

    def to_ical
      "#{@latitude.to_ical};#{@longitude.to_ical}"
    end
  end

  # The body of the iCalendar object consists of a sequence of calendar
  # properties and one or more calendar components. The calendar
  # properties are attributes that apply to the calendar as a whole. The
  # calendar components are collections of properties that express a
  # particular calendar semantic. For example, the calendar component can
  # specify an Event, a Todo, a Journal entry, Timezone information, or
  # Freebusy time information, or an Alarm.
  class Component < Icalendar::Base

    CAL_EXTENSION_REGEX = /\Ax_[a-z_]+=?\Z/

    meta_include HashAttrs

    attr_reader :name
    attr_accessor :properties

    @@multi_properties = {}
    @@multiline_properties = {}

    def initialize(name)
      @name = name
      @components = Hash.new { |h, k| h[k] = [] }
      @properties = {}

      @@logger.info("New #{@name[1,@name.size].capitalize}...")
    end

    # Add a sub-component to the current component object.
    def add_component(component)
      @components[component.key_name] << component
    end

    # Add a component to the calendar.
    alias add add_component

    # Add an event to the calendar.
    alias add_event add_component

    # Add a todo item to the calendar.
    alias add_todo add_component

    # Add a journal item to the calendar.
    alias add_journal add_component

    def remove_component(component)
      @components[component.key_name].delete(component)
    end

    # Remove a component from the calendar.
    alias remove remove_component

    # Remove an event from the calendar.
    alias remove_event remove_component

    # Remove a todo item from the calendar.
    alias remove_todo remove_component

    # Remove a journal item from the calendar.
    alias remove_journal remove_component

    # Used to generate unique component ids
    def new_uid
      "#{DateTime.now}_#{rand(999999999)}@#{Socket.gethostname}"
    end

    # Output in the icalendar format
    def to_ical
      printer do
        [print_headers,
          print_properties,
          print_subcomponents].join
      end
    end

    # Print this icalendar component
    def print_component
      to_ical
    end

    def print_subcomponents
      @components.values.map do |component_parts|
        Array(component_parts).map &:to_ical
      end.join
    end

    def printer
      ["BEGIN:#{@name.upcase}\r\n",
      yield,
      "END:#{@name.upcase}\r\n"].join
    end

    def print_properties(properties = properties_to_print)
      excludes = %w(geo rrule categories exdate)
      properties.sort.map do |key, val|
        property = fix_conflict_with_built_in(key)
        prelude = property.gsub(/_/, '-').upcase

        if multiline_property? property
          val.map do |part|
            params = print_parameters part
            value = escape_chars ":#{part.to_ical}"
            chunk_lines "#{prelude}#{params}#{value}"
          end.join
        else
          params = print_parameters val
          value = ":#{val.to_ical}"
          value = escape_chars(value) unless excludes.include? property
          chunk_lines "#{prelude}#{params}#{value}"
        end
      end.join
    end

    # Take out underscore for property names that conflicted
    # with built-in words.
    def fix_conflict_with_built_in(key)
      key.sub(/\Aip_/, '')
    end

    def escape_chars(value)
      value.gsub("\\", "\\\\").gsub("\r\n", "\n").gsub("\r", "\n").gsub("\n", "\\n").gsub(",", "\\,").gsub(";", "\\;")
    end

    def chunk_lines(str, length = MAX_LINE_LENGTH, separator = "\r\n ")
      chunks = str.scan(/.{1,#{length}}/)
      lines = chunks.join(separator) << separator
      lines.gsub(/ *$/, '')
    end

    # Print the parameters for a specific property.
    def print_parameters(value)
      return "" unless value.respond_to?(:ical_params)

      Array(value.ical_params).map do |key, val|
        val = Array(val)
        next if val.empty?

        escaped = val.map { |v| Parser.escape(v.to_ical) }.join(',')
        ";#{key}=" << escaped
      end.join
    end

    def properties_to_print
      @properties # subclasses can exclude properties
    end

    def print_headers
      "" # subclasses can specify headers
    end

    # TODO: Look into the x-property, x-param stuff...
    # This would really only be needed for subclassing to add additional
    # properties to an application using the API.
    def custom_property(name, value)
      @properties[name] = value
    end

    def multi_property?(name)
      @@multi_properties.has_key?(name.downcase)
    end

    def multiline_property?(name)
      @@multiline_properties.has_key?(name.downcase)
    end

    # Make it protected so we can monitor usage...
    protected

    def key_name
      (self.class.to_s.downcase + 's').gsub('icalendar::', '').to_sym
    end

    def self.ical_component(*syms)
      hash_accessor :@components, *syms
    end

    # Define a set of methods supporting a new property
    def self.ical_property(property, alias_name = nil, prop_name = nil)
      property = "#{property}".strip.downcase
      alias_name = "#{alias_name}".strip.downcase unless alias_name.nil?
      # If a prop_name was given then we use that for the actual storage
      property = "#{prop_name}".strip.downcase unless prop_name.nil?

      generate_getter(property, alias_name)
      generate_setter(property, alias_name)
      generate_query(property, alias_name)
    end

    # Define a set of methods defining a new property, which
    # supports multiple values for the same property name.
    def self.ical_multi_property(property, singular, plural)
      property = "#{property}".strip.downcase.gsub(/-/, '_')
      plural = "#{plural}".strip.downcase

      # Set this key so the parser knows to use an array for
      # storing this property type.
      @@multi_properties["#{property}"] = true

      generate_multi_getter(property, plural)
      generate_multi_setter(property, plural)
      generate_multi_query(property, plural)
      generate_multi_adder(property, singular)
      generate_multi_remover(property, singular)
    end

    # Define a set of methods defining a new property, which
    # supports multiple values in multiple lines with same property name
    def self.ical_multiline_property(property, singular, plural)
      @@multiline_properties["#{property}"] = true
      ical_multi_property(property, singular, plural)
    end


    private

    def self.generate_getter(property, alias_name)
      unless instance_methods.include? property
        code = <<-code
            def #{property}(val = nil, params = nil)
              return @properties["#{property}"] if val.nil?

              unless val.respond_to?(:to_ical)
                raise(NotImplementedError, "Value of type (" + val.class.to_s + ") does not support to_ical method!")
              end

              unless params.nil?
                val = FrozenProxy.new val if val.frozen?
                # Extend with the parameter methods only if we have to...
                unless val.respond_to?(:ical_params)
                  val.class.class_eval { attr_accessor :ical_params }
                end
                val.ical_params = params
              end

              @properties["#{property}"] = val
            end
        code

        class_eval code, "component.rb", 219
        alias_method("#{alias_name}", "#{property}") unless alias_name.nil?
      end
    end

    def self.generate_setter(property, alias_name)
      setter = property + '='
      unless instance_methods.include? setter
        code = <<-code
            def #{setter}(val)
              #{property}(val)
            end
        code

        class_eval code, "component.rb", 233
        alias_method("#{alias_name}=", "#{property+'='}") unless alias_name.nil?
      end
    end

    def self.generate_query(property, alias_name)
      query = "#{property}?"
      unless instance_methods.include? query
        code = <<-code
            def #{query}
              @properties.has_key?("#{property.downcase}")
            end
        code

        class_eval code, "component.rb", 226

        alias_method("#{alias_name}\?", "#{query}") unless alias_name.nil?
      end
    end

    def self.generate_multi_getter(property, plural)
      # Getter for whole array
      unless instance_methods.include? plural
        code = <<-code
            def #{plural}(a = nil, params = nil)
              if a.nil?
                @properties["#{property}"] || []
              else
                self.#{plural}=(a).tap do |val|
                  unless params.nil?
                    unless val.respond_to?(:ical_params)
                      val.class.class_eval { attr_accessor :ical_params }
                    end
                    val.ical_params = params
                  end
                end
              end
            end
        code

        class_eval code, "component.rb", 186
        alias_method property, plural
      end
    end

    def self.generate_multi_setter(property, plural)
      # Setter for whole array
      unless instance_methods.include? plural+'+'
        code = <<-code
            def #{plural}=(a)
              if a.respond_to?(:to_ary)
                @properties["#{property}"] = a.to_ary
              elsif a =~ /^[^"].*(?<!\\\\),.*[^"]$/
                @properties["#{property}"] = a.split(/(?<!\\\\),/).to_ary
              else
                (@properties["#{property}"] ||= []) << a
              end
            end
        code

        class_eval code, "component.rb", 198
      end
    end

    def self.generate_multi_query(property, plural)
      # Query for any of these properties
      unless instance_methods.include? plural+'?'
        code = <<-code
            def #{plural}?
              @properties.has_key?("#{property}")
            end
        code

        class_eval code, "component.rb", 210
      end
    end

    def self.generate_multi_adder(property, singular)
      adder = "add_"+singular.to_s
      # Add another item to this properties array
      unless instance_methods.include? adder
        code = <<-code
            def #{adder}(val, params = {})
              unless val.respond_to?(:to_ical)
                raise(NotImplementedError, "Property value object does not support to_ical method!")
              end

              unless params.nil?
                # Extend with the parameter methods only if we have to...
                unless val.respond_to?(:ical_params)
                  val.class.class_eval { attr_accessor :ical_params }
                end
                val.ical_params = params
              end

              if @properties.has_key?("#{property}")
                @properties["#{property}"] << val
              else
                @properties["#{property}"] = [val]
              end
            end
        code

        class_eval code, "component.rb", 289
        alias_method("add_#{property.downcase}", "#{adder}")
      end
    end

    def self.generate_multi_remover(property, singular)
      # Remove an item from this properties array
      unless instance_methods.include? "remove_#{singular}"
        code = <<-code
            def remove_#{singular}(a)
              if @properties.has_key?("#{property}")
                @properties["#{property}"].delete(a)
              end
            end
        code

        class_eval code, "component.rb", 303
        alias_method("remove_#{property.downcase}", "remove_#{singular}")
      end
    end

    public

    def method_missing(method_name, *args, &block)
      # Allow proprietary calendar extensions to be set
      #
      # Example:
      #   cal.x_wr_calname = "iCalendar Calendar"
      if method_name =~ CAL_EXTENSION_REGEX

        # Make sure to remove '=' from the end of the method_name so we can
        # define it
        name = method_name.to_s.chomp '='

        self.class.class_eval do
          ical_multiline_property name, name, name
        end
        send method_name, *args
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s =~ CAL_EXTENSION_REGEX || super
    end
  end # class Component
end
