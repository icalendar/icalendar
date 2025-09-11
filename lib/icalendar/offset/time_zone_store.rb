# frozen_string_literal: true

module Icalendar
  class Offset
    class TimeZoneStore < Offset
      def valid?
        timezone_store && tz_info
      end

      def normalized_value
        # plan b - use definition from provided `VTIMEZONE`
        offset = tz_info.offset_for_local(value).to_s

        Icalendar.logger.debug("Plan b - parsing #{value.to_fs(:default)} with offset: #{offset}")
        if value.respond_to?(:change)
          value.change offset: offset
        else
          ::Time.new value.year, value.month, value.day, value.hour, value.min, value.sec, offset
        end
      end

      private

      def tz_info
        @tz_info ||= timezone_store.retrieve(tzid)
      end
    end
  end
end
