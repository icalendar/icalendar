# frozen_string_literal: true

module Icalendar

  class Calendar < Component
    required_property :version
    required_property :prodid
    optional_single_property :calscale
    optional_single_property :ip_method
    optional_property :ip_name
    optional_property :description
    optional_single_property :uid
    optional_single_property :last_modified, Icalendar::Values::DateTime, true
    optional_single_property :url, Icalendar::Values::Uri, true
    optional_property :categories, Icalendar::Values::Text, false, false, true
    optional_single_property :refresh_interval, Icalendar::Values::Duration, true
    optional_single_property :source, Icalendar::Values::Uri, true
    optional_single_property :color
    optional_property :image, Icalendar::Values::Uri, false, true

    component :timezone, :tzid
    component :event
    component :todo
    component :journal
    component :freebusy

    def initialize
      super 'calendar'
      self.prodid = 'icalendar-ruby'
      self.version = '2.0'
      self.calscale = 'GREGORIAN'
    end

    def publish
      self.ip_method = 'PUBLISH'
      self
    end

    def request
      self.ip_method = 'REQUEST'
      self
    end

    def reply
      self.ip_method = 'REPLY'
      self
    end

    def add
      self.ip_method = 'ADD'
      self
    end

    def cancel
      self.ip_method = 'CANCEL'
      self
    end

    def refresh
      self.ip_method = 'REFRESH'
      self
    end

    def counter
      self.ip_method = 'COUNTER'
      self
    end

    def decline_counter
      self.ip_method = 'DECLINECOUNTER'
      self
    end

   module MergesTimezones
      def timezone(tz = nil)
        tz ||= Icalendar::Timezone.new
        tz.parent = self
        yield tz if block_given?
        return tz if timezones.any? { |existing| existing.equal? tz }

        existing = timezones.find { |candidate| !tz.tzid.nil? && candidate.tzid.to_s == tz.tzid.to_s }
        existing ? existing.merge!(tz) : add_component(tz)
      end

      def rebuild_timezones
        return self unless defined?(TZInfo::Timezone) &&
                          TZInfo::Timezone.method_defined?(:ical_timezone_for_range)

        dates = event_dates_by_tzid
        rebuilt = {}
        kept = timezones.each_with_object([]) do |tz, list|
          tzid = tz.tzid.nil? ? nil : tz.tzid.to_s
          next list << tz unless dates.key?(tzid)
          next if rebuilt.key?(tzid)

          zone = tzinfo_timezone(tzid)
          next list << tz if zone.nil?

          list << (rebuilt[tzid] = timezone_for_dates(zone, dates[tzid]))
        end

        # TZIDs used by events without a timezone in the calendar
        present = timezones.map { |tz| tz.tzid.to_s unless tz.tzid.nil? }
        dates.each do |tzid, tz_dates|
          next if present.include?(tzid)
          zone = tzinfo_timezone(tzid)
          kept << timezone_for_dates(zone, tz_dates) unless zone.nil?
        end

        timezones.replace kept
        self
      end
    end
    prepend MergesTimezones

    private

    # Local wall-clock times for each TZID used by the events. An RRULE UNTIL
    # in UTC is a lambda converting it to local time once the zone is known.
    def event_dates_by_tzid
      events.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |event, dates|
        values = [event.dtstart, event.dtend, event.recurrence_id, *event.rdate, *event.exdate]
        each_date_value(values) do |value|
          tzid = Array(value.ical_params['tzid']).first
          dates[tzid.to_s] << wall_clock(value.to_datetime) unless tzid.nil?
        end

        tzid = event.dtstart && Array(event.dtstart.ical_params['tzid']).first
        next if tzid.nil?
        event.rrule.each do |rule|
          next if rule.until.nil?
          dates[tzid.to_s] << rrule_until(rule.until)
        end
      end
    end

    def timezone_for_dates(zone, dates)
      locals = dates.map { |date| date.respond_to?(:call) ? date.call(zone) : date }
      zone.ical_timezone_for_range(locals.min, locals.max).tap { |tz| tz.parent = self }
    end

    def each_date_value(values, &block)
      values.each do |value|
        if value.is_a?(Icalendar::Values::Helpers::Array)
          each_date_value value.value, &block
        elsif value.is_a?(Icalendar::Value)
          yield value
        end
      end
    end

    def rrule_until(value)
      parsed = Icalendar::Values::DateOrDateTime.new(value).call
      if parsed.is_a?(Icalendar::Values::Date)
        date = parsed.value
        return ::DateTime.new(date.year, date.month, date.day, 23, 59, 59)
      end
      return wall_clock(parsed.to_datetime) unless value.end_with?('Z')
      ->(zone) { wall_clock(zone.utc_to_local(parsed.to_time.utc).to_datetime) }
    end

    def wall_clock(datetime)
      ::DateTime.new(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
    end

    def tzinfo_timezone(identifier)
      TZInfo::Timezone.get identifier
    rescue TZInfo::InvalidTimezoneIdentifier
      nil
    end

  end

end
