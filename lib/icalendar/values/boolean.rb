module Icalendar
  module Values

    class Boolean < Value

      def initialize(value, params = {}, include_value_param = false)
        super value.to_s.downcase == 'true', params, include_value_param
      end

      def value_ical
        value ? 'TRUE' : 'FALSE'
      end

    end

  end
end