require 'date'

module Icalendar
  module Values

    class Date < Value
      FORMAT = '%Y%m%d'

      def initialize(value, params = {})
        if value.respond_to? :to_date
          super value.to_date, params
        elsif value.is_a? String
          super ::Date.strptime(value, FORMAT), params
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