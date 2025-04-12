# frozen_string_literal: true

module Icalendar
  class Offset
    class ActiveSupportExact < Icalendar::Offset
      def valid?
        support_classes_defined? && tz
      end

      def normalized_value
        Icalendar.logger.debug("Plan a - parsing #{value}/#{tzid} as ActiveSupport::TimeWithZone")
        # plan a - use ActiveSupport::TimeWithZone
        Icalendar::Values::Helpers::ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
      end

      private

      def tz
        @tz ||= ActiveSupport::TimeZone[tzid]
      end
    end
  end
end
