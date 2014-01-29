require 'ice_cube'

module Icalendar
  class Occurrence < Struct.new(:start_time, :end_time)
  end

  class Schedule
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def timezone
      event.start.icalendar_tzid.to_s.gsub(/^(["'])|(["'])$/, "") if event.start.respond_to?(:icalendar_tzid)
    end

    def rrules
      event.rrule
    end

    def start_time
      TimeUtil.to_time(event.start)
    end

    def end_time
      TimeUtil.to_time(event.end)
    end

    def occurrences_between(begin_time, closing_time)
      ice_cube_occurrences = ice_cube_schedule.occurrences_between(TimeUtil.to_time(begin_time), TimeUtil.to_time(closing_time))

      ice_cube_occurrences.map do |occurrence|
        convert_ice_cube_occurrence(occurrence)
      end
    end

    def convert_ice_cube_occurrence(ice_cube_occurrence)
      if timezone
        begin
          tz = TZInfo::Timezone.get(timezone)
          start_time = tz.local_to_utc(ice_cube_occurrence.start_time)
          end_time = tz.local_to_utc(ice_cube_occurrence.end_time)
        rescue TZInfo::InvalidTimezoneIdentifier => e
          warn "Unknown TZID specified in ical event (#{timezone.inspect}), ignoring (may cause recurrence to be at wrong time)"
        end
      end

      start_time ||= ice_cube_occurrence.start_time
      end_time ||= ice_cube_occurrence.end_time
      
      Icalendar::Occurrence.new(start_time, end_time)
    end

    def ice_cube_schedule
      schedule = IceCube::Schedule.new
      schedule.start_time = start_time
      schedule.end_time = end_time

      rrules.each do |rrule|
        ice_cube_recurrence_rule = convert_rrule_to_ice_cube_recurrence_rule(rrule)
        schedule.add_recurrence_rule(ice_cube_recurrence_rule)
      end

      event.exdate.each do |exception_date|
        exception_date = Time.parse(exception_date) if exception_date.is_a?(String)
        schedule.add_exception_time(TimeUtil.to_time(exception_date))
      end

      schedule
    end

    def transform_byday_to_hash(byday_entries)
      hashable_array = Array(byday_entries).map {|byday| convert_byday_to_ice_cube_day_of_week_hash(byday) }.flatten(1)
      hash = Hash[*hashable_array]

      if hash.values.include?([0]) # byday interval not specified (e.g., BYDAY=SA not BYDAY=1SA)
        hash.keys
      else
        hash
      end
    end

    private


    def convert_rrule_to_ice_cube_recurrence_rule(rrule)
      ice_cube_recurrence_rule = base_ice_cube_recurrence_rule(rrule.frequency, rrule.interval)

      ice_cube_recurrence_rule.tap do |r|
        days = transform_byday_to_hash(rrule.by_list.fetch(:byday))
        r.month_of_year(rrule.by_list.fetch(:bymonth)) if rrule.by_list.fetch(:bymonth)
        r.day_of_month(rrule.by_list.fetch(:bymonthday)) if rrule.by_list.fetch(:bymonthday)
        r.day_of_week(days) if days.is_a?(Hash) and !days.empty?
        r.day(days) if days.is_a?(Array) and !days.empty?
        r.until(TimeUtil.to_time(rrule.until)) if rrule.until
        r.count(rrule.count)
      end

      ice_cube_recurrence_rule
    end

    def base_ice_cube_recurrence_rule(frequency, interval)
      if frequency == "DAILY"
        IceCube::DailyRule.new(interval)
      elsif frequency == "WEEKLY"
        IceCube::WeeklyRule.new(interval)
      elsif frequency == "MONTHLY"
        IceCube::MonthlyRule.new(interval)
      elsif frequency == "YEARLY"
        IceCube::YearlyRule.new(interval)
      else
        raise "Unknown frequency: #{rrule.frequency}"
      end
    end

    def convert_byday_to_ice_cube_day_of_week_hash(byday)
      day_code = byday.day
      position = Array(byday.position).map(&:to_i)

      day_symbol = case day_code.to_s
      when "SU" then :sunday
      when "MO" then :monday
      when "TU" then :tuesday
      when "WE" then :wednesday
      when "TH" then :thursday
      when "FR" then :friday
      when "SA" then :saturday
      else
        raise ArgumentError.new "Unexpected ical_day: #{ical_day.inspect}"
      end

      [day_symbol, position]
    end
  end
end