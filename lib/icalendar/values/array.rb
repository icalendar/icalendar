module Icalendar
  module Values

    class Array < Value

      def initialize(value, klass, params = {}, options = {})
        @value_delimiter = options[:delimiter] || ','
        mapped = if value.is_a? ::Array
                   value.map { |v| klass.new v, params }
                 else
                   [klass.new(value, params)]
                 end
        super mapped, params
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

      def valid?
        klass = value.first.class
        !value.all? { |v| v.class == klass }
      end

      def value_type
        value.first.value_type
      end

      private

      def needs_value_type?(default_type)
        value.first.class != default_type
      end

    end

  end
end
