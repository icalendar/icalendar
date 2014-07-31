require 'date'

module Icalendar
  module Values

    class Date < Value
      FORMAT = '%Y%m%d'

      def initialize(value, params = {})
        if value.is_a? String
          super ::Date.strptime(value, FORMAT), params
        elsif value.respond_to? :to_date
          super value.to_date, params
        else
          super
        end
      end

      def value_ical
        value.strftime FORMAT
      end

      def <=>(other)
        self.value <=> other.value
      end

    end

  end
end
