# frozen_string_literal: true

begin
  require 'active_support/time'

  if defined?(ActiveSupport::TimeWithZone)
    require_relative 'active_support_time_with_zone_adapter'
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
    module Helpers
      module TimeWithZone
        attr_reader :tz_utc, :timezone_store

        def initialize(value, params = {})
          params = Icalendar::DowncasedHash(params)
          @tz_utc = params['tzid'] == 'UTC'
          @timezone_store = params.delete 'x-tz-store'
          super (offset_value(value, params) || value), params
        end

        def __getobj__
          orig_value = super
          if set_offset?
            orig_value
          else
            offset = offset_value(orig_value, ical_params)
            __setobj__(offset) unless offset.nil?
            offset || orig_value
          end
        end

        def params_ical
          ical_params.delete 'tzid' if tz_utc
          super
        end

        private

        def offset_value(value, params)
          @offset_value = unless params.nil? || params['tzid'].nil?
            tzid = params['tzid'].is_a?(::Array) ? params['tzid'].first : params['tzid']
            support_classes_defined = defined?(ActiveSupport::TimeZone) && defined?(ActiveSupportTimeWithZoneAdapter)
            if support_classes_defined && (tz = ActiveSupport::TimeZone[tzid])
              Icalendar.logger.debug("Plan a - parsing #{value}/#{tzid} as ActiveSupport::TimeWithZone")
              # plan a - use ActiveSupport::TimeWithZone
              ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
            elsif !timezone_store.nil? && !(x_tz_info = timezone_store.retrieve(tzid)).nil?
              # plan b - use definition from provided `VTIMEZONE`
              offset = x_tz_info.offset_for_local(value).to_s
              Icalendar.logger.debug("Plan b - parsing #{value} with offset: #{offset}")
              if value.respond_to?(:change)
                value.change offset: offset
              else
                ::Time.new value.year, value.month, value.day, value.hour, value.min, value.sec, offset
              end
            elsif support_classes_defined && (tz = ActiveSupport::TimeZone[tzid.split.first])
              # plan c - try to find an ActiveSupport::TimeWithZone based on the first word of the tzid
              Icalendar.logger.debug("Plan c - parsing #{value}/#{tz.tzinfo.name} as ActiveSupport::TimeWithZone")
              params['tzid'] = [tz.tzinfo.name]
              ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
            else
              # plan d - just ignore the tzid
              Icalendar.logger.info("Ignoring timezone #{tzid} for time #{value}")
              nil
            end
          end
        end

        def set_offset?
          !!@offset_value
        end
      end
    end
  end
end
