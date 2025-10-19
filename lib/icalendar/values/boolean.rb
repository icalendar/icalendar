# frozen_string_literal: true

module Icalendar
  module Values

    class Boolean < Value

      def initialize(value, *args)
        super value.to_s.downcase == 'true', *args
      end

      def value_ical
        value ? 'TRUE' : 'FALSE'
      end

    end

  end
end
