# frozen_string_literal: true

module Icalendar
  class Offset
    class ActiveSupportPartial < Offset
      def valid?
        support_classes_defined? && tz
      end

      def normalized_value
        # plan c - try to find an ActiveSupport::TimeWithZone based on the first word of the tzid
        Icalendar.logger.debug("Plan c - parsing #{value.to_fs(:default)}/#{tz.tzinfo.name} as ActiveSupport::TimeWithZone")
        Icalendar::Values::Helpers::ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
      end

      def normalized_tzid
        [tz.tzinfo.name]
      end

      private

      def tz
        @tz ||= ActiveSupport::TimeZone[tzid.split.first]
      end
    end
  end
end
