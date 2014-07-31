require 'date'
require_relative 'time_with_zone'

module Icalendar
  module Values

    class DateTime < Value
      include TimeWithZone

      FORMAT = '%Y%m%dT%H%M%S'

      def initialize(value, params = {})
        if value.is_a? String
          params['tzid'] = 'UTC' if value.end_with? 'Z'
          super ::DateTime.strptime(value, FORMAT), params
        elsif value.respond_to? :to_datetime
          super value.to_datetime, params
        else
          super
        end
      end

      def value_ical
        if tz_utc
          "#{strftime FORMAT}Z"
        else
          strftime FORMAT
        end
      end

      def <=>(other)
        self.value <=> other.value
      end

    end

  end
end
