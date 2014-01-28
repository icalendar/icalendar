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

    def occurrences_between(begin_time, closing_time)
      occurrences = ice_cube_schedule.occurrences_between(TimeUtil.to_time(begin_time), TimeUtil.to_time(closing_time))

      occurrences.map do |occurrence|
        if timezone
          tz = TZInfo::Timezone.get(timezone)
          start_time = tz.local_to_utc(occurrence.start_time)
          end_time = tz.local_to_utc(occurrence.end_time)  
        else
          start_time = occurrence.start_time
          end_time = occurrence.end_time
        end
        
        Icalendar::Occurrence.new(start_time, end_time)
      end
    end

    def ice_cube_schedule
      schedule = IceCube::Schedule.new
      schedule.start_time = start_time
      schedule.end_time = end_time

      rrules.each do |rrule|

        ice_cube_recurrence_rule = if rrule.frequency == "DAILY"
          IceCube::DailyRule.new(rrule.interval)
        elsif rrule.frequency == "WEEKLY"
          IceCube::WeeklyRule.new(rrule.interval)
        elsif rrule.frequency == "MONTHLY"
          IceCube::MonthlyRule.new(rrule.interval)
        elsif rrule.frequency == "YEARLY"
          IceCube::YearlyRule.new(rrule.interval).tap do |yearly_rule|
            yearly_rule.month_of_year(rrule.by_list.fetch(:bymonth)) if rrule.by_list.fetch(:bymonth)
            yearly_rule.day_of_month(rrule.by_list.fetch(:bymonthday)) if rrule.by_list.fetch(:bymonthday)
          end
        else
          raise "Unknown frequency: #{rrule.frequency}"
        end

        ice_cube_recurrence_rule.day_of_month(rrule.by_list.fetch(:bymonthday)) if rrule.by_list.fetch(:bymonthday)

        days = transform_byday_to_hash(rrule.by_list.fetch(:byday))
        ice_cube_recurrence_rule.day(days) if days.is_a?(Array) and !days.empty?
        ice_cube_recurrence_rule.day_of_week(days) if days.is_a?(Hash) and !days.empty?

        ice_cube_recurrence_rule.until(TimeUtil.to_time(rrule.until)) if rrule.until
        ice_cube_recurrence_rule.count(rrule.count)

        schedule.add_recurrence_rule(ice_cube_recurrence_rule)
      end

      event.exdate.each do |exception_date|
        exception_date = Time.parse(exception_date) if exception_date.is_a?(String)
        schedule.add_exception_time(TimeUtil.to_time(exception_date))
      end

      schedule
    end

    def transform_byday_to_hash(byday)
      hash = {}
      Array(byday).map do |byday|
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
      end.each do |two_el_array|
        hash[two_el_array.first] = two_el_array.last
      end

      if hash.values.find {|position| position != [0] }
        hash
      else
        hash.keys
      end
    end

    def start_time
      TimeUtil.to_time(event.start)
    end

    def end_time
      TimeUtil.to_time(event.end)
    end
  end
end