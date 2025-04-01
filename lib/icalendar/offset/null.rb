# frozen_string_literal: true

module Icalendar
  class Offset
    class Null < Offset
      def valid?
        true
      end

      def normalized_value
        # plan d - just ignore the tzid
        Icalendar.logger.info("Ignoring timezone #{tzid} for time #{value}")
        nil
      end
    end
  end
end
