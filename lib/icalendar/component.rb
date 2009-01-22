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
    alias :long :longitude

    def initialize(lat, long)
      @lat = lat
      @long = long
    end

    def to_ical
      "#{@lat.to_ical};#{@long.to_ical}"
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

    meta_include HashAttrs

    attr_reader :name
    attr_accessor :properties

    @@multi_properties = {}
    @@multiline_properties = {}

    def initialize(name)
      @name = name
      @components = Hash.new([])
      @properties = {}

      @@logger.info("New #{@name[1,@name.size].capitalize}...")
    end

    # Add a sub-component to the current component object.
    def add_component(component)
      key = (component.class.to_s.downcase + 's').gsub('icalendar::', '').to_sym

      unless @components.has_key? key
        @components[key] = []
      end

      @components[key] << component
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
      key = (component.class.to_s.downcase + 's').gsub('icalendar::', '').to_sym

      if @components.has_key? key
        @components[key].delete(component)
      end
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
      print_component do
        s = ""
        @components.each_value do |comps|
          comps.each { |component| s << component.to_ical }
        end
        s
      end
    end

    # Print this icalendar component
    def print_component
      # Begin a new component
      "BEGIN:#{@name.upcase}\r\n" +

      # Then the properties
      print_properties +

      # sub components
      yield +

      # End of this component
      "END:#{@name.upcase}\r\n"
    end

    # Print this components properties
    def print_properties
      s = ""

      @properties.each do |key,val| 
        # Take out underscore for property names that conflicted
        # with built-in words.
        if key =~ /ip_.*/
          key = key[3..-1]
        end

        # Property name
        unless multiline_property?(key)
           prelude = "#{key.gsub(/_/, '-').upcase}" + 

           # Possible parameters
           print_parameters(val) 

           # Property value
           value = ":#{val.to_ical}" 
           add_sliced_text(s,prelude+escape_chars(value))
         else 
           prelude = "#{key.gsub(/_/, '-').upcase}" 
            val.each do |v| 
               params = print_parameters(v)
               value = ":#{v.to_ical}"
               add_sliced_text(s,prelude + params + escape_chars(value))
            end
         end
      end
      s
    end

    def escape_chars(value)
      value.gsub("\\", "\\\\").gsub("\n", "\\n").gsub(",", "\\,").gsub(";", "\\;")
    end

    def add_sliced_text(add_to,escaped)
      escaped = escaped.split('') # split is unicdoe-aware when `$KCODE = 'u'`
      add_to << escaped.shift(MAX_LINE_LENGTH).to_s << "\r\n " while escaped.length != 0
      add_to.gsub!(/ *$/, '')
    end

    # Print the parameters for a specific property
    def print_parameters(val)
      s = ""
      return s unless val.respond_to?(:ical_params) and not val.ical_params.nil?

      val.ical_params.each do |key,val|
        s << ";#{key}"
        val = [ val ] unless val.is_a?(Array)

        # Possible parameter values
        unless val.empty?
          s << "="
          sep = "" # First entry comes after = sign, but then we need commas
          val.each do |pval| 
            if pval.respond_to? :to_ical 
              s << sep << pval.to_ical
              sep = ","
            end
          end
        end
      end
      s
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

    def Component.ical_component(*syms)
      hash_accessor :@components, *syms
    end

    # Define a set of methods supporting a new property
    def Component.ical_property(property, alias_name = nil, prop_name = nil)
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
    def Component.ical_multi_property(property, singular, plural)
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
    def Component.ical_multiline_property(property, singular, plural)
      @@multiline_properties["#{property}"] = true
      ical_multi_property(property, singular, plural)
    end


    private

    def Component.generate_getter(property, alias_name)
      unless instance_methods.include? property
        code = <<-code
            def #{property}(val = nil, params = nil)
              return @properties["#{property}"] if val.nil?

              unless val.respond_to?(:to_ical)
                raise(NotImplementedError, "Value of type (" + val.class.to_s + ") does not support to_ical method!")
              end

              unless params.nil?
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

    def Component.generate_setter(property, alias_name)
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

    def Component.generate_query(property, alias_name)
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

    def Component.generate_multi_getter(property, plural)     
      # Getter for whole array
      unless instance_methods.include? plural
        code = <<-code
            def #{plural}(a = nil)
              if a.nil?
                @properties["#{property}"] || []
              else
                self.#{plural}=(a)
              end 
            end
        code

        class_eval code, "component.rb", 186
      end
    end

    def Component.generate_multi_setter(property, plural)
      # Setter for whole array
      unless instance_methods.include? plural+'+'
        code = <<-code
            def #{plural}=(a)
              if a.respond_to?(:to_ary)
                a.to_ary.each do |val|
                  unless val.respond_to?(:to_ical)
                    raise(NotImplementedError, "Property values do not support to_ical method!")
                  end
                end

                @properties["#{property}"] = a.to_ary
              else
                raise ArgumentError, "#{plural} is a multi-property that must be an array! Use the add_[property] method to add single entries."
              end
            end
        code

        class_eval code, "component.rb", 198
      end
    end

    def Component.generate_multi_query(property, plural)
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

    def Component.generate_multi_adder(property, singular)
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

    def Component.generate_multi_remover(property, singular)
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

    def method_missing(method_name, *args)
      @@logger.debug("Inside method_missing...")
      method_name = method_name.to_s.downcase

      unless method_name =~ /x_.*/
        raise NoMethodError, "Method Name: #{method_name}"
      end

      # x-properties are accessed with underscore but stored with a dash so
      # they output correctly and we don't have to special case the
      # output code, which would require checking every property.
      if args.size > 0 # Its a setter
        # Pull off the possible equals
        @properties[method_name[/x_[^=]*/].gsub('x_', 'x-')] = args.first
      else # Or its a getter
        return @properties[method_name.gsub('x_', 'x-')]
      end
    end

    public

    def respond_to?(method_name)
      unless method_name.to_s.downcase =~ /x_.*/
        super
      end

      true
    end

  end # class Component
end
