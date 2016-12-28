module Icalendar
  module Values
    module ComparableDates
      def <=>(other)
        if other.is_a?(Icalendar::Values::Date) || other.is_a?(Icalendar::Values::DateTime)
          value_ical <=> other.value_ical
        else
          nil
        end
      end
    end
  end
end
