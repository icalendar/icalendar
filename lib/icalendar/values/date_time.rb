require 'date'

module Icalendar
  module Values

    class DateTime < Value
      FORMAT = '%Y%m%dT%H%M%S'

      def initialize(value, params = {})
        # TODO deal with timezones (Z on end of UTC string)
        if value.respond_to? :to_datetime
          super value.to_datetime, params
        elsif value.is_a? String
          super DateTime.strptime(value, FORMAT), params
        else
          super
        end
      end

      def value_ical
        value.strftime FORMAT
      end

    end

  end
end