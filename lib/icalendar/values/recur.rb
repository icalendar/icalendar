# frozen_string_literal: true

require 'ostruct'

module Icalendar
  module Values

    class Recur < Value
      NUM_LIST = '\d{1,2}(?:,\d{1,2})*'
      DAYNAME = 'SU|MO|TU|WE|TH|FR|SA'
      WEEKDAY = "(?:[+-]?\\d{1,2})?(?:#{DAYNAME})"
      MONTHDAY = '[+-]?\d{1,2}'
      YEARDAY = '[+-]?\d{1,3}'
      RECUR = Struct.new(:frequency, :until, :count, :interval, :by_second, :by_minute, :by_hour, :by_day, :by_month_day, :by_year_day, :by_week_number, :by_month, :by_set_position, :week_start)

      def initialize(value, params = {})
        if value.is_a? Icalendar::Values::Recur
          super value.value, params
        else
          super  RECUR.new(*parse_fields(value).values_at(*RECUR.members)), params
         
        end
      end

      def valid?
        return false if frequency.nil?
        return false if !self.until.nil? && !count.nil?
        true
      end

      def value_ical
        builder = ["FREQ=#{frequency}"]
        builder << "UNTIL=#{self.until}" unless self.until.nil?
        builder << "COUNT=#{count}" unless count.nil?
        builder << "INTERVAL=#{interval}" unless interval.nil?
        builder << "BYSECOND=#{by_second.join ','}" unless by_second.nil?
        builder << "BYMINUTE=#{by_minute.join ','}" unless by_minute.nil?
        builder << "BYHOUR=#{by_hour.join ','}" unless by_hour.nil?
        builder << "BYDAY=#{by_day.join ','}" unless by_day.nil?
        builder << "BYMONTHDAY=#{by_month_day.join ','}" unless by_month_day.nil?
        builder << "BYYEARDAY=#{by_year_day.join ','}" unless by_year_day.nil?
        builder << "BYWEEKNO=#{by_week_number.join ','}" unless by_week_number.nil?
        builder << "BYMONTH=#{by_month.join ','}" unless by_month.nil?
        builder << "BYSETPOS=#{by_set_position.join ','}" unless by_set_position.nil?
        builder << "WKST=#{week_start}" unless week_start.nil?
        builder.join ';'
      end

      private

      PARSE_FIELDS_FREQUENCY_REGEX = /FREQ=(SECONDLY|MINUTELY|HOURLY|DAILY|WEEKLY|MONTHLY|YEARLY)/i.freeze
      PARSE_FIELDS_UNTIL_REGEX = /UNTIL=([^;]*)/i.freeze
      PARSE_FIELDS_COUNT_REGEX = /COUNT=(\d+)/i.freeze
      PARSE_FIELDS_INTERVAL_REGEX = /INTERVAL=(\d+)/i.freeze
      PARSE_FIELDS_BY_SECOND_REGEX = /BYSECOND=(#{NUM_LIST})(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_MINUTE_REGEX = /BYMINUTE=(#{NUM_LIST})(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_HOUR_REGEX = /BYHOUR=(#{NUM_LIST})(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_DAY_REGEX = /BYDAY=(#{WEEKDAY}(?:,#{WEEKDAY})*)(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_MONTH_DAY_REGEX = /BYMONTHDAY=(#{MONTHDAY}(?:,#{MONTHDAY})*)(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_YEAR_DAY_REGEX = /BYYEARDAY=(#{YEARDAY}(?:,#{YEARDAY})*)(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_WEEK_NUMBER_REGEX = /BYWEEKNO=(#{MONTHDAY}(?:,#{MONTHDAY})*)(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_MONTH_REGEX = /BYMONTH=(#{NUM_LIST})(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_SET_POSITON_REGEX = /BYSETPOS=(#{YEARDAY}(?:,#{YEARDAY})*)(?:;|\z)/i.freeze
      PARSE_FIELDS_BY_WEEK_START_REGEX = /WKST=(#{DAYNAME})/i.freeze

      def parse_fields(value)
        {
          frequency: (value =~ PARSE_FIELDS_FREQUENCY_REGEX ? $1.upcase : nil),
          until: (value =~ PARSE_FIELDS_UNTIL_REGEX ? $1 : nil),
          count: (value =~ PARSE_FIELDS_COUNT_REGEX ? $1.to_i : nil),
          interval: (value =~ PARSE_FIELDS_INTERVAL_REGEX ? $1.to_i : nil),
          by_second: (value =~ PARSE_FIELDS_BY_SECOND_REGEX ? $1.split(',').map { |i| i.to_i } : nil),
          by_minute: (value =~ PARSE_FIELDS_BY_MINUTE_REGEX ? $1.split(',').map { |i| i.to_i } : nil),
          by_hour: (value =~ PARSE_FIELDS_BY_HOUR_REGEX ? $1.split(',').map { |i| i.to_i } : nil),
          by_day: (value =~ PARSE_FIELDS_BY_DAY_REGEX ? $1.split(',') : nil),
          by_month_day: (value =~ PARSE_FIELDS_BY_MONTH_DAY_REGEX ? $1.split(',') : nil),
          by_year_day: (value =~ PARSE_FIELDS_BY_YEAR_DAY_REGEX ? $1.split(',') : nil),
          by_week_number: (value =~ PARSE_FIELDS_BY_WEEK_NUMBER_REGEX ? $1.split(',') : nil),
          by_month: (value =~ PARSE_FIELDS_BY_MONTH_REGEX ? $1.split(',').map { |i| i.to_i } : nil),
          by_set_position: (value =~ PARSE_FIELDS_BY_SET_POSITON_REGEX ? $1.split(',') : nil),
          week_start: (value =~ PARSE_FIELDS_BY_WEEK_START_REGEX ? $1.upcase : nil)
        }
      end
    end
  end
end
