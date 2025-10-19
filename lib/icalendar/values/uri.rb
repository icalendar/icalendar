# frozen_string_literal: true

require 'uri'

module Icalendar
  module Values

    class Uri < Value

      def initialize(value, *args)
        parsed = URI.parse(value) rescue value
        super parsed, *args
      end

      def value_ical
        value.to_s
      end
    end

  end
end
