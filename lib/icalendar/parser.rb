require 'icalendar/timezone_store'
require 'icalendar/parser/node_extensions'
require 'icalendar/parser/ics_parser.treetop'

module Icalendar

  class Parser
    class ParseError < StandardError; end

    attr_writer :component_class
    attr_reader :source, :strict, :timezone_store, :parser

    def initialize(source, strict = false)
      if source.respond_to? :read
        @source = source
      elsif source.respond_to? :to_s
        @source = StringIO.new source.to_s, 'r'
      else
        msg = 'Icalendar::Parser.new must be called with a String or IO object'
        Icalendar.fatal msg
        fail ArgumentError, msg
      end
      @strict = strict
      @timezone_store = TimezoneStore.new
      @parser = IcsParser.new
    end

    def parse
      components = []
      parsed_elements.each do |tree|
        if !strict? || tree.component.class == component_class
          components << parse_component(tree)
        else
          fail "Expected to parse a #{component_class.name}, instead found a #{tree.component.class.name}"
        end
      end
      components
    end

    def strict?
      !!@strict
    end

    def ics_data
      source.read.gsub(/\r\n[ \t]/, "")
    end

    def parse_partial_tree(component)
      parsed_elements.each do |tree|
        if tree.is_a? Ics::PropertyLine
          assign_property component, tree
        else
          assign_component component, tree
        end
      end
      component
    end

    private

    def parse_component(tree)
      tree.properties.each do |property|
        assign_property tree.component, property
      end
      tree.components.each do |component|
        assign_component tree.component, component
      end
      tree.component
    end

    def assign_component(parent_component, ics_component)
      ical_component = parse_component ics_component
      timezone_store.store(ical_component) if ical_component.name == "timezone"
      parent_component.add_component ical_component
    end

    def assign_property(component, line)
      prop_name = %w(class method).include?(line.property_name) ? "ip_#{line.property_name}" : line.property_name
      multi_property = component.class.multiple_properties.include? prop_name
      prop_value = wrap_property_value component, line, multi_property
      begin
        method_name = multi_property ? "append_#{prop_name}" : "#{prop_name}="
        component.send method_name, prop_value
      rescue NoMethodError => nme
        if strict?
          Icalendar.logger.error "No method \"#{method_name}\" for component #{component}"
          raise nme
        else
          Icalendar.logger.debug "No method \"#{method_name}\" for component #{component}. Appending to custom"
          component.append_custom_property prop_name, prop_value
        end
      end
    end

    def wrap_property_value(component, line, multi_property)
      klass = get_wrapper_class component, line
      set_tzid_info line
      if wrap_in_array? klass, line.property_value, multi_property
        delimiter = line.property_value.match(/(?<!\\)([,;])/)[1]
        Icalendar::Values::Array.new line.property_value.split(/(?<!\\)[;,]/),
                                     klass,
                                     line.property_params,
                                     delimiter: delimiter
      else
        klass.new line.property_value, line.property_params
      end
    rescue Icalendar::Values::DateTime::FormatError => fe
      raise fe if strict?
      line.property_params['value'] = ['DATE']
      retry
    end

    def set_tzid_info(line)
      tzid = line.property_params['tzid'] or return
      line.property_params['x-tz-info'] = timezone_store.retrieve tzid.first
    end

    def wrap_in_array?(klass, value, multi_property)
      klass.value_type != 'RECUR' &&
        ((multi_property && value =~ /(?<!\\)[,;]/) || value =~ /(?<!\\);/)
    end

    def get_wrapper_class(component, line)
      klass = component.class.default_property_types[line.property_name]
      if !line.property_params['value'].nil?
        klass_name = line.property_params.delete('value').first
        unless klass_name.upcase == klass.value_type
          klass_name = klass_name.downcase.gsub(/(?:\A|-)(.)/) { |m| m[-1].upcase }
          klass = Icalendar::Values.const_get klass_name if Icalendar::Values.const_defined?(klass_name)
        end
      end
      klass
    end

    def component_class
      @component_class ||= Icalendar::Calendar
    end

    def parsed_elements
      result = parser.parse(ics_data)
      if result.nil?
        Icalendar.logger.error "Failed to parse: #{parser.failure_reason}"
        fail ParseError, parser.failure_reason
      else
        result.elements
      end
    end
  end
end
