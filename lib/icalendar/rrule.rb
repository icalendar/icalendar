=begin
  Copyright (C) 2008 Rick (http://github.com/rubyredrick)

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'date'
require 'uri'
require 'stringio'

module Icalendar

  # This class is not yet fully functional..
  #
  # Gem versions < 1.1.0.0 used to return a string for the recurrence_rule component,
  # but now it returns this Icalendar::RRule class. ie It's not backwards compatible!
  #
  # To get the original RRULE value from a parsed feed, use the 'orig_value' property.
  #
  # Example:
  #   rules = event.recurrence_rules.map{ |rule| rule.orig_value }

  class RRule < Icalendar::Base

    class Weekday
      def initialize(day, position)
        @day, @position = day, position
      end

      def to_s
        "#{@position}#{@day}"
      end
    end

    attr_accessor :frequency, :until, :count, :interval, :by_list, :wkst

    def initialize(name, params, value)
      @value = value
      frequency_match = value.match(/FREQ=(SECONDLY|MINUTELY|HOURLY|DAILY|WEEKLY|MONTHLY|YEARLY)/)
      @frequency = frequency_match[1]
      @until = parse_date_val("UNTIL", value)
      @count = parse_int_val("COUNT", value)
      @interval = parse_int_val("INTERVAL", value)
      @by_list = {:bysecond => parse_int_list("BYSECOND", value)}
      @by_list[:byminute] = parse_int_list("BYMINUTE",value)
      @by_list[:byhour] = parse_int_list("BYHOUR", value)
      @by_list[:byday] = parse_weekday_list("BYDAY", value)
      @by_list[:bymonthday] = parse_int_list("BYMONTHDAY", value)
      @by_list[:byyearday] = parse_int_list("BYYEARDAY", value)
      @by_list[:byweekno] = parse_int_list("BYWEEKNO", value)
      @by_list[:bymonth] = parse_int_list("BYMONTH", value)
      @by_list[:bysetpos] = parse_int_list("BYSETPOS", value)
      @wkst = parse_wkstart(value)
    end

    # Returns the original pre-parsed RRULE value.
    def orig_value
      @value
    end

    def to_ical
      raise Icalendar::InvalidPropertyValue.new("FREQ must be specified for RRULE values") unless frequency
      raise Icalendar::InvalidPropertyValue.new("UNTIL and COUNT must not both be specified for RRULE values") if [self.until, count].compact.length > 1
      result = ["FREQ=#{frequency}"]
      result << "UNTIL=#{self.until.to_ical}" if self.until
      result << "COUNT=#{count}" if count
      result << "INTERVAL=#{interval}" if interval
      by_list.each do |key, value|
        result << "#{key.to_s.upcase}=#{value.join ','}" if value
      end
      result << "WKST=#{wkst}" if wkst
      result.join ';'
    end

    def parse_date_val(name, string)
      match = string.match(/;#{name}=(.*?)(Z)?(;|$)/)
      if match
        DateTime.parse(match[1]).tap do |dt|
          dt.icalendar_tzid = 'UTC' unless match[2].nil?
        end
      end
    end

    def parse_int_val(name, string)
      match = string.match(/;#{name}=(\d+)(;|$)/)
      match ? match[1].to_i : nil
    end

    def parse_int_list(name, string)
      match = string.match(/;#{name}=([+-]?.*?)(;|$)/)
      if match
        match[1].split(",").map {|int| int.to_i}
      else
        nil
      end
    end

    def parse_weekday_list(name, string)
      match = string.match(/;#{name}=(.*?)(;|$)/)
      if match
        return_array = match[1].split(",").map do |weekday|
          wd_match = weekday.match(/([+-]?\d*)(SU|MO|TU|WE|TH|FR|SA)/)
          Weekday.new(wd_match[2], wd_match[1])
        end
      else
        nil
      end
      return_array
    end

    def parse_wkstart(string)
      match = string.match(/;WKST=(SU|MO|TU|WE|TH|FR|SA)(;|$)/)
      if match
        match[1]
      else
        nil
      end
    end

    # TODO: Incomplete
    def occurrences_of_event_starting(event, datetime)
      initial_start = event.dtstart
      (0...count).map do |day_offset|
        occurrence = event.clone
        occurrence.dtstart = initial_start + day_offset
        occurrence.clone
      end
    end
  end

end
