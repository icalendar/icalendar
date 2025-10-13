# frozen_string_literal: true

module Icalendar
  module Values

    class Integer < Value

      def initialize(value, *args)
        super value.to_i, *args
      end

      def value_ical
        value.to_s
      end

    end

  end
end
