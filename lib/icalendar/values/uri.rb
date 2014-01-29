require 'uri'

module Icalendar
  module Values

    class Uri < Value

      def initialize(value, params = {}, include_value_param = false)
        parsed = URI.parse value rescue value
        super parsed, params, include_value_param
      end

      def value_ical
        value.to_s
      end
    end

  end
end