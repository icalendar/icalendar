require 'date'
require_relative 'comparable_dates'
require_relative 'parsable_dates'

module Icalendar
  module Values

    class Date < Value
      include ComparableDates
      include ParsableDates

      FORMAT = '%Y%m%d'

      def initialize(value, params = {})
        if value.is_a? String
          parsing(value, FORMAT) { |parsed_date| super(parsed_date, params) }
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
        if other.is_a?(Icalendar::Values::Date) || other.is_a?(Icalendar::Values::DateTime)
          value_ical <=> other.value_ical
        else
          nil
        end
      end
    end
  end
end
