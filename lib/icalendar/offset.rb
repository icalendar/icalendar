# frozen_string_literal: true

module Icalendar
  class Offset
    def self.build(value, params, timezone_store)
      return nil if params.nil? || params['tzid'].nil?

      tzid = Array(params['tzid']).first

      [
        Icalendar::Offset::ActiveSupportExact,
        Icalendar::Offset::TimeZoneStore,
        Icalendar::Offset::WindowsToIana,
        Icalendar::Offset::ActiveSupportPartial,
        Icalendar::Offset::Null
      ].lazy.map { |klass| klass.new(tzid, value, timezone_store) }.detect(&:valid?)
    end

    def initialize(tzid, value, timezone_store)
      @tzid = tzid
      @value = value
      @timezone_store = timezone_store
    end

    def normalized_tzid
      Array(tzid)
    end

    private

    attr_reader :tzid, :value, :timezone_store

    def support_classes_defined?
      defined?(ActiveSupport::TimeZone) &&
        defined?(Icalendar::Values::Helpers::ActiveSupportTimeWithZoneAdapter)
    end
  end
end

require_relative 'offset/active_support_exact'
require_relative 'offset/active_support_partial'
require_relative 'offset/null'
require_relative 'offset/time_zone_store'
require_relative 'offset/windows_to_iana'
