require 'icalendar/timezone_store'

module Icalendar

  class Parser
    attr_writer :component_class
    attr_reader :source, :strict, :timezone_store, :verbose

    def self.clean_bad_wrapping(source)
      content = if source.respond_to? :read
        source.read
      elsif source.respond_to? :to_s
        source.to_s
      else
        msg = 'Icalendar::Parser.clean_bad_wrapping must be called with a String or IO object'
        Icalendar.fatal msg
        fail ArgumentError, msg
      end
      encoding = content.encoding
      content.force_encoding(Encoding::ASCII_8BIT)
      content.gsub(/\r?\n[ \t]/, "").force_encoding(encoding)
    end

    def initialize(source, strict = false, verbose = false)
      if source.respond_to? :gets
        @source = source
      elsif source.respond_to? :to_s
        @source = StringIO.new source.to_s, 'r'
      else
        msg = 'Icalendar::Parser.new must be called with a String or IO object'
        Icalendar.fatal msg
        fail ArgumentError, msg
      end
      read_in_data
      @strict = strict
      @verbose = verbose
      @timezone_store = TimezoneStore.new
    end

    def parse
      components = []
      while (fields = next_fields)
        component = component_class.new
        if fields[:name] == 'begin' && fields[:value].downcase == component.ical_name.downcase
          components << parse_component(component)
        end
      end
      components
    end

    def parse_property(component, fields = nil)
      fields = next_fields if fields.nil?
      prop_name = %w(class method).include?(fields[:name]) ? "ip_#{fields[:name]}" : fields[:name]
      multi_property = component.class.multiple_properties.include? prop_name
      prop_value = wrap_property_value component, fields, multi_property
      begin
        method_name = if multi_property
          "append_#{prop_name}"
        else
          "#{prop_name}="
        end
        component.send method_name, prop_value
      rescue NoMethodError => nme
        if strict?
          Icalendar.logger.error "No method \"#{method_name}\" for component #{component}"
          raise nme
        else
          Icalendar.logger.warn "No method \"#{method_name}\" for component #{component}. Appending to custom." if verbose?
          component.append_custom_property prop_name, prop_value
        end
      end
    end

    def wrap_property_value(component, fields, multi_property)
      klass = get_wrapper_class component, fields
      if wrap_in_array? klass, fields[:value], multi_property
        delimiter = fields[:value].match(/(?<!\\)([,;])/)[1]
        Icalendar::Values::Array.new fields[:value].split(/(?<!\\)[;,]/),
                                     klass,
                                     fields[:params],
                                     delimiter: delimiter
      else
        klass.new fields[:value], fields[:params]
      end
    rescue Icalendar::Values::DateTime::FormatError => fe
      raise fe if strict?
      fields[:params]['value'] = ['DATE']
      retry
    end

    def wrap_in_array?(klass, value, multi_property)
      klass.value_type != 'RECUR' &&
        ((multi_property && value =~ /(?<!\\)[,;]/) || value =~ /(?<!\\);/)
    end

    def get_wrapper_class(component, fields)
      klass = component.class.default_property_types[fields[:name]]
      if !fields[:params]['value'].nil?
        klass_name = fields[:params].delete('value').first
        unless klass_name.upcase == klass.value_type
          klass_name = "Icalendar::Values::#{klass_name.downcase.gsub(/(?:\A|-)(.)/) { |m| m[-1].upcase }}"
          klass = Object.const_get klass_name if Object.const_defined?(klass_name)
        end
      end
      klass
    end

    def strict?
      !!@strict
    end

    def verbose?
      @verbose
    end

    private

    def component_class
      @component_class ||= Icalendar::Calendar
    end

    def parse_component(component)
      while (fields = next_fields)
        if fields[:name] == 'end'
          klass_name = fields[:value].gsub(/\AV/, '').downcase.capitalize
          timezone_store.store(component) if klass_name == 'Timezone'
          break
        elsif fields[:name] == 'begin'
          klass_name = fields[:value].gsub(/\AV/, '').gsub("-", "_").downcase.capitalize
          Icalendar.logger.debug "Adding component #{klass_name}"
          if Object.const_defined? "Icalendar::#{klass_name}"
            component.add_component parse_component(Object.const_get("Icalendar::#{klass_name}").new)
          elsif Object.const_defined? "Icalendar::Timezone::#{klass_name}"
            component.add_component parse_component(Object.const_get("Icalendar::Timezone::#{klass_name}").new)
          else
            component.add_custom_component klass_name, parse_component(Component.new klass_name.downcase, fields[:value])
          end
        else
          parse_property component, fields
        end
      end
      component
    end

    def read_in_data
      @data = source.gets and @data.chomp!
    end

    def next_fields
      line = @data or return nil
      loop do
        read_in_data
        if @data =~ /\\$/
          #$stderr.puts "Input is #{@data.inspect}, line: #{line.inspect}"
          # \ escaped newline?
          # get next line amended
          line << "\n"
          read_in_data
          @data = " " + @data
        end
        if @data =~ /\A[ \t].+\z/
          line << @data[1, @data.size]
        elsif @data !~ /\A\s*\z/
          break
        end
      end
      line.gsub!("\\n","\n")
      #$stderr.puts "parse line1: #{line.inspect}"
      parse_fields line
    end

    NAME = '[-a-zA-Z0-9]+'
    QSTR = '"[^"]*"'
    PTEXT = '[^";:,]*'
    PVALUE = "(?:#{QSTR}|#{PTEXT})"
    PARAM = "(#{NAME})=(#{PVALUE}(?:,#{PVALUE})*)"
    VALUE = '.*'
    LINE = "(?<name>#{NAME})(?<params>(?:;#{PARAM})*):(?<value>#{VALUE})"
    BAD_LINE = "(?<name>#{NAME})(?<params>(?:;#{PARAM})*)"

    def parse_fields(input)
      if parts = %r{#{LINE}}.match(input)
        value = parts[:value]
      else
        parts = %r{#{BAD_LINE}}.match(input) unless strict?
        parts or fail "Invalid iCalendar input line: #{input}"
        # Non-strict and bad line so use a value of empty string
        value = ''
      end

      params = {}
      parts[:params].scan %r{#{PARAM}} do |match|
        param_name = match[0].downcase
        params[param_name] ||= []
        match[1].scan %r{#{PVALUE}} do |param_value|
          if param_value.size > 0
            param_value = param_value.gsub(/\A"|"\z/, '')
            params[param_name] << param_value
            if param_name == 'tzid'
              params['x-tz-info'] = timezone_store.retrieve param_value
            end
          end
        end
      end
      # Building the string to send to the logger is expensive.
      # Only do it if the logger is at the right log level.
      if ::Logger::DEBUG >= Icalendar.logger.level
        Icalendar.logger.debug "Found fields: #{parts.inspect} with params: #{params.inspect}"
      end
      {
        name: parts[:name].downcase.gsub('-', '_'),
        params: params,
        value: value
      }
    end
  end
end
