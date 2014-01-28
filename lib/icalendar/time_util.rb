require 'tzinfo'

module Icalendar
  module TimeUtil
    def datetime_to_time(datetime)
      raise ArgumentError, "Must pass a DateTime object (#{datetime.class} passed instead)" unless datetime.is_a? DateTime
      hour_minute_utc_offset = timezone_to_hour_minute_utc_offset(datetime.icalendar_tzid, datetime.to_date) || datetime.strftime("%:z")

      Time.new(datetime.year, datetime.month, datetime.mday, datetime.hour, datetime.min, datetime.sec, hour_minute_utc_offset)
    end

    def date_to_time(date)
      raise ArgumentError, "Must pass a Date object (#{date.class} passed instead)" unless date.is_a? Date
      Time.new(date.year, date.month, date.mday)
    end

    def to_time(time_object)
      if time_object.is_a?(Time)
        time_object
      elsif time_object.is_a?(DateTime)
        datetime_to_time(time_object)
      elsif time_object.is_a?(Date)
        date_to_time(time_object)
      else
        raise ArgumentError, "Unsupported time object passed: #{time_object.inspect}"
      end
    end

    def timezone_to_hour_minute_utc_offset(tzid, time_period = Time.now)
      utc_time_period = to_time(time_period).utc
      tzid = tzid.to_s.gsub(/^(["'])|(["'])$/, "")
      utc_offset =  TZInfo::Timezone.get(tzid).period_for_utc(utc_time_period).utc_total_offset # this seems to work, but I feel like there is a lurking bug
      hour_offset = utc_offset/60/60
      hour_offset = "+#{hour_offset}" if hour_offset >= 0
      match = hour_offset.to_s.match(/(\+|-)(\d+)/)
      "#{match[1]}#{match[2].rjust(2, "0")}:00"
    rescue TZInfo::InvalidTimezoneIdentifier => e
      nil
    end

    extend self
  end
end
