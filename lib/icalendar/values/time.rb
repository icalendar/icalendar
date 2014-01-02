require 'date'

module Icalendar
  module Values

    class Time < Value
      FORMAT = '%H%M%S'

      def initialize(value, params = {}, include_value_param = false)
        # TODO deal with timezones again!
        if value.respond_to? :to_time
          super value.to_time, params, include_value_param
        elsif value.is_a? String
          super ::DateTime.strptime(value, FORMAT).to_time, params, include_value_param
        else
          super
        end
      end

      def value_ical
        if utc_offset == 0 && ical_params['tzid'].nil?
          "#{strftime FORMAT}Z"
        else
          strftime FORMAT
        end
      end

    end

  end
end