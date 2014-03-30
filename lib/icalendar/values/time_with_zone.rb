begin
  require 'active_support/time'
rescue LoadError
  $stderr.puts "Info: No TimeWithZone support"
end

module Icalendar
  module Values
    module TimeWithZone
      attr_reader :tz_utc

      def initialize(value, params = {})
        @tz_utc = params['tzid'] == 'UTC'

        if defined?(ActiveSupport) && !params['tzid'].nil?
          tzid = params['tzid'].is_a?(::Array) ? params['tzid'].first : params['tzid']
          zone = ActiveSupport::TimeZone[tzid]
          value = ActiveSupport::TimeWithZone.new nil, zone, value unless zone.nil?
          super value, params
        else
          super
        end
      end

      def params_ical
        ical_params.delete 'tzid' if tz_utc
        super
      end
    end
  end
end
