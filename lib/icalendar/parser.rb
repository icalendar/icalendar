module Icalendar

  class Parser

    attr_reader :source, :strict

    def initialize(source, strict = true)
      if source.respond_to? :gets
        @source = source
      elsif source.respond_to? :to_s
        @source = StringIO.new source.to_s, 'r'
      else
        raise ArgumentError, 'Icalendar::Parser.new must be called with a String or IO object'
      end
      @strict = strict
    end

    def parse
      source.rewind
      @data = source.gets and @data.chomp!
      calendars = []
      while (fields = next_fields)
        if fields[:name] == 'begin' && fields[:value].downcase == 'vcalendar'
          calendars << parse_component(Calendar.new)
        end
      end
      calendars
    end

    private

    def parse_component(component)
      while (fields = next_fields)
        if fields[:name] == 'end'
          break
        elsif fields[:name] == 'begin'
          klass_name = fields[:value].gsub(/\AV/, '').downcase.capitalize
          if Icalendar.const_defined? klass_name
            component.add_component parse_component(Icalendar.const_get(klass_name).new)
          else
            component.add_component parse_component(Component.new klass_name.downcase, fields[:value])
          end
        else
          # new property
          klass = component.class.default_property_types[fields[:name]]
          include_value_param = false
          if !fields[:params]['value'].nil?
            klass_name = fields[:params].delete('value').first
            unless klass_name.upcase == klass.value_type
              include_value_param = true
              klass_name = klass_name.downcase.gsub(/(?:\A|-)(.)/) { |m| m[-1].upcase }
              klass = Icalendar::Values.const_get klass_name if Icalendar::Values.const_defined?(klass_name)
            end
          end
          if fields[:value] =~ /(?<!\\)([,;])/
            delimiter = $1
            prop_value = Icalendar::Values::Array.new fields[:value].split(/(?<!\\)[;,]/),
                                                      klass,
                                                      fields[:params],
                                                      include_value_param: include_value_param, delimiter: delimiter
          else
            prop_value = klass.new fields[:value], fields[:params], include_value_param
          end
          prop_name = %w(class method).include?(fields[:name]) ? "ip_#{fields[:name]}" : fields[:name]
          if component.class.multiple_properties.include? prop_name
            component.send "append_#{prop_name}", prop_value
          else
            component.send "#{prop_name}=", prop_value
          end
        end
      end
      component
    end

    def next_fields
      line = @data or return nil
      loop do
        @data = source.gets and @data.chomp!
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

    def parse_fields(input)
      parts = %r{#{LINE}}.match(input) or raise "Invalid iCalendar input line: #{input}"
      params = {}
      parts[:params].scan %r{#{PARAM}} do |match|
        param_name = match[0].downcase
        params[param_name] ||= []
        match[1].scan %r{#{PVALUE}} do |param_value|
          params[param_name] << param_value.gsub(/\A"|"\z/, '') if param_value.size > 0
        end
      end
      {
        name: parts[:name].downcase.gsub('-', '_'),
        params: params,
        value: parts[:value]
      }
    end
  end
end