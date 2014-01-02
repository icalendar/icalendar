module Icalendar
  module Values

    class Integer < Value

      def initialize(value, params = {}, include_value_param = false)
        super value.to_i, params, include_value_param
      end

      def value_ical
        value.to_s
      end

    end

  end
end