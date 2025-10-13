# frozen_string_literal: true

require "icalendar/offset"

begin
  require 'active_support'
  require 'active_support/time'

  if defined?(ActiveSupport::TimeWithZone)
    require_relative 'active_support_time_with_zone_adapter'
  end
rescue LoadError
  # tis ok, just a bit less fancy
end

module Icalendar
  module Values
    module Helpers
      module TimeWithZone
        attr_reader :tz_utc, :timezone_store

        def initialize(value, params = {}, context = {})
          params = Icalendar::DowncasedHash(params)
          @tz_utc = params['tzid'] == 'UTC'
          @timezone_store = params.delete 'x-tz-store'

          offset = Icalendar::Offset.build(value, params, timezone_store)

          unless offset.nil?
            @offset_value = offset.normalized_value
            params['tzid'] = offset.normalized_tzid
          end

          super (@offset_value || value), params, context
        end

        def __getobj__
          orig_value = super
          if set_offset?
            orig_value
          else
            new_value = Icalendar::Offset.build(orig_value, ical_params, timezone_store)&.normalized_value
            __setobj__(new_value) unless new_value.nil?
            new_value || orig_value
          end
        end

        def params_ical
          ical_params.delete 'tzid' if tz_utc
          super
        end

        private

        def set_offset?
          !!@offset_value
        end
      end
    end
  end
end
