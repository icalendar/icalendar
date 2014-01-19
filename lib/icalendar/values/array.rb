module Icalendar
  module Values

    class Array < Value

      def initialize(value, klass, params = {}, options = {})
        @value_delimiter = options[:delimiter] || ','
        mapped = if value.nil? || value.is_a?(Icalendar::Value)
                   [value]
                 elsif value.is_a? ::Array
                   value.map do |v|
                     if v.nil? || v.is_a?(Icalendar::Value)
                       v
                     else
                       klass.new v, params
                     end
                   end
                 else
                   [klass.new(value, params)]
                 end
        super mapped, params, options[:include_value_param]
      end

      def params_ical
        value.each do |v|
          ical_params.merge! v.ical_params
        end
        super
      end

      def value_ical
        value.map do |v|
          v.value_ical
        end.join @value_delimiter
      end
    end

  end
end