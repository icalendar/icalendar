# frozen_string_literal: true

module Icalendar
  module Values

    class Float < Value

      def initialize(value, *args)
        super value.to_f, *args
      end

      def value_ical
        value.to_s
      end

    end

  end
end
