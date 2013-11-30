require 'date'

module Icalendar
  module Values

    class Time < Value
      FORMAT = '%H%M%S'

      def initialize(value, params = {})
        # TODO deal with timezones again!
        if value.respond_to? :to_time
          super value.to_time, params
        elsif value.is_a? String
          super DateTime.strptime(value, FORMAT).to_time, params
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