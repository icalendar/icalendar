module Icalendar

  class Parser

    attr_reader :source, :strict

    def initialize(source, strict = false)
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
    end

    def parse
      source.rewind
      read_in_data
      calendars = []
      while (fields = next_fields)
        if fields[:name] == 'begin' && fields[:value].downcase == 'vcalendar'
          calendars << parse_component(Calendar.new)
        end
      end
      calendars
    end

    def parse_property(component, fields = nil)
      fields = next_fields if fields.nil?
      klass = component.class.default_property_types[fields[:name]]
      if !fields[:params]['value'].nil?
        klass_name = fields[:params].delete('value').first
        unless klass_name.upcase == klass.value_type
          klass_name = klass_name.downcase.gsub(/(?:\A|-)(.)/) { |m| m[-1].upcase }
          klass = Icalendar::Values.const_get klass_name if Icalendar::Values.const_defined?(klass_name)
        end
      end
      if klass.value_type != 'RECUR' && fields[:value] =~ /(?<!\\)([,;])/
        delimiter = $1
        prop_value = Icalendar::Values::Array.new fields[:value].split(/(?<!\\)[;,]/),
                                                  klass,
                                                  fields[:params],
                                                  delimiter: delimiter
      else
        prop_value = klass.new fields[:value], fields[:params].merge(:strict => strict?)
      end
      prop_name = %w(class method).include?(fields[:name]) ? "ip_#{fields[:name]}" : fields[:name]
      begin
        method_name = if component.class.multiple_properties.include? prop_name
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
          Icalendar.logger.warn "No method \"#{method_name}\" for component #{component}. Appending to custom."
          component.append_custom_property prop_name, prop_value
        end
      end
    end

    def strict?
      !!@strict
    end

    private

    def parse_component(component)
      while (fields = next_fields)
        if fields[:name] == 'end'
          break
        elsif fields[:name] == 'begin'
          klass_name = fields[:value].gsub(/\AV/, '').downcase.capitalize
          Icalendar.logger.debug "Adding component #{klass_name}"
          if Icalendar.const_defined? klass_name
            component.add_component parse_component(Icalendar.const_get(klass_name).new)
          elsif Icalendar::Timezone.const_defined? klass_name
            component.add_component parse_component(Icalendar::Timezone.const_get(klass_name).new)
          else
            component.add_component parse_component(Component.new klass_name.downcase, fields[:value])
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
        if @data =~ /\A[ \t].+\z/
          line << @data[1, @data.size]
        elsif @data !~ /\A\s*\z/
          break
        end
      end
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
          params[param_name] << param_value.gsub(/\A"|"\z/, '') if param_value.size > 0
        end
      end
      Icalendar.logger.debug "Found fields: #{parts.inspect} with params: #{params.inspect}"
      {
        name: parts[:name].downcase.gsub('-', '_'),
        params: params,
        value: value
      }
    end
  end
end
