# frozen_string_literal: true

begin
  require 'active_support/time'

  if defined?(ActiveSupport::TimeWithZone)
    require 'icalendar/values/active_support_time_with_zone_adapter'
  end
rescue NameError
  # ActiveSupport v7+ needs the base require to be run first before loading
  # specific parts of it.
  # https://guides.rubyonrails.org/active_support_core_extensions.html#stand-alone-active-support
  require 'active_support'
  retry
rescue LoadError
  # tis ok, just a bit less fancy
end

module Icalendar
  module Values
    class TimeWithZone
      attr_reader :tz_utc

      def initialize(value, params = {})
        params = Icalendar::DowncasedHash(params)
        @tz_utc = params['tzid'] == 'UTC'
        x_tz_info = params.delete 'x-tz-info'

        offset_value = unless params['tzid'].nil?
          tzid = params['tzid'].is_a?(::Array) ? params['tzid'].first : params['tzid']
          support_classes_defined = defined?(ActiveSupport::TimeZone) && defined?(ActiveSupportTimeWithZoneAdapter)
          if support_classes_defined && (tz = ActiveSupport::TimeZone[tzid])
            # plan a - use ActiveSupport::TimeWithZone 
            ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
          elsif !x_tz_info.nil?
            # plan b - use definition from provided `VTIMEZONE`
            offset = x_tz_info.offset_for_local(value).to_s
            if value.respond_to?(:change)
              value.change offset: offset
            else
              ::Time.new value.year, value.month, value.day, value.hour, value.min, value.sec, offset
            end
          elsif support_classes_defined && (tz = ActiveSupport::TimeZone[tzid.split.first])
            # plan c - try to find an ActiveSupport::TimeWithZone based on the first word of the tzid
            params['tzid'] = [tz.tzinfo.name]
            ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
          end
          # plan d - just ignore the tzid
        end
        super((offset_value || value), params)
      end

      def params_ical
        ical_params.delete 'tzid' if tz_utc
        super
      end
    end
  end
end
