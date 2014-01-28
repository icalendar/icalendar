=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'ice_cube'

module Icalendar
  # A Event calendar component is a grouping of component
  # properties, and possibly including Alarm calendar components, that
  # represents a scheduled amount of time on a calendar. For example, it
  # can be an activity; such as a one-hour long, department meeting from
  # 8:00 AM to 9:00 AM, tomorrow. Generally, an event will take up time
  # on an individual calendar.
  class Event < Component
    ical_component :alarms

    ## Single instance properties

    # Access classification (PUBLIC, PRIVATE, CONFIDENTIAL...)
    ical_property :ip_class, :klass

    # Date & time of creation
    ical_property :created

    # Complete description of the calendar component
    ical_property :description

    # Specifies the timezone for the event
    attr_accessor :tzid

    # Specifies date-time when calendar component begins
    ical_property :dtstart, :start

    # Latitude & longitude for specified activity
    ical_property :geo, :geo_location

    # Date & time this item was last modified
    ical_property :last_modified

    # Specifies the intended venue for this activity
    ical_property :location

    # Defines organizer of this item
    ical_property :organizer

    # Defines relative priority for this item (1-9... 1 = best)
    ical_property :priority

    # Indicate date & time when this item was created
    ical_property :dtstamp, :timestamp

    # Revision sequence number for this item
    ical_property :sequence, :seq

    # Defines overall status or confirmation of this item
    ical_property :status
    ical_property :summary
    ical_property :transp, :transparency

    # Defines a persistent, globally unique id for this item
    ical_property :uid, :unique_id

    # Defines a URL associated with this item
    ical_property :url
    ical_property :recurrence_id, :recurid

    ## Single but mutually exclusive properties (Not testing though)

    # Specifies a date and time that this item ends
    ical_property :dtend, :end

    # Specifies a positive duration time
    ical_property :duration

    ## Multi-instance properties

    # Associates a URI or binary blob with this item
    ical_multi_property :attach, :attachment, :attachments

    # Defines an attendee for this calendar item
    ical_multiline_property :attendee, :attendee, :attendees

    # Defines the categories for a calendar component (school, work...)
    ical_multi_property :categories, :category, :categories

    # Simple comment for the calendar user.
    ical_multi_property :comment, :comment, :comments

    # Contact information associated with this item.
    ical_multi_property :contact, :contact, :contacts
    ical_multi_property :exdate, :exception_date, :exception_dates
    ical_multi_property :exrule, :exception_rule, :exception_rules
    ical_multi_property :rstatus, :request_status, :request_statuses

    # Used to represent a relationship between two calendar items
    ical_multi_property :related_to, :related_to, :related_tos
    ical_multi_property :resources, :resource, :resources

    # Used with the UID & SEQUENCE to identify a specific instance of a
    # recurring calendar item.
    ical_multi_property :rdate, :recurrence_date, :recurrence_dates
    ical_multi_property :rrule, :recurrence_rule, :recurrence_rules

    def initialize()
      super("VEVENT")

      # Now doing some basic initialization
      sequence 0
      timestamp DateTime.now
      uid new_uid
    end

    def alarm(&block)
      a = Alarm.new
      self.add a

      a.instance_eval(&block) if block

      a
    end

    # This is the original way
    def occurrences_starting(time)
      recurrence_rules.first.occurrences_of_event_starting(self, time)
    end

    # This is the ice_cube-powered way
    def occurrences_between(begin_time, closing_time)
      occurrences = schedule.occurrences_between(TimeUtil.to_time(begin_time), TimeUtil.to_time(closing_time))
      if timezone
        occurrences.map do |occurrence|
          tz = TZInfo::Timezone.get(timezone)
          properly_offset_start_time = tz.local_to_utc(occurrence.start_time)
          properly_offset_end_time = tz.local_to_utc(occurrence.end_time)
          IceCube::Occurrence.new(properly_offset_start_time, properly_offset_end_time)
        end
      else
        occurrences
      end
    end

    def timezone
      start.icalendar_tzid.to_s.gsub(/^(["'])|(["'])$/, "") if start.respond_to?(:icalendar_tzid)
    end

    def rrules
      rrule
    end

    def schedule
      schedule = IceCube::Schedule.new
      schedule.start_time = TimeUtil.to_time(start)
      schedule.end_time = self.end

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

        ice_cube_recurrence_rule
          .until(rrule.until)
          .count(rrule.count)

        schedule.add_recurrence_rule(ice_cube_recurrence_rule)
      end

      exdate.each do |exception_date|
        exception_date = Time.parse(exception_date) if exception_date.is_a?(String)
        schedule.add_exception_time(TimeUtil.to_time(exception_date))
      end

      schedule
    end

    def convert_ical_day_to_sym(ical_day)
      occ = ical_day.position || ""
      day_code = ical_day.day

      raise ical_day unless day_code || occ

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

      # [day_symbol, occ]
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
      TimeUtil.to_time(self.start)
    end

  end
end

# Put this in it's own file.

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
