# frozen_string_literal: true

require 'ostruct'

module Icalendar
  module Values

    class Duration < Value

      def initialize(value, *args)
        if value.is_a? Icalendar::Values::Duration
          super value.value, *args
        else
          super OpenStruct.new(parse_fields value), *args
        end
      end

      def past?
        value.past
      end

      def value_ical
        return "#{'-' if past?}P#{weeks}W" if weeks > 0
        builder = []
        builder << '-' if past?
        builder << 'P'
        builder << "#{days}D" if days > 0
        builder << 'T' if time?
        builder << "#{hours}H" if hours > 0
        builder << "#{minutes}M" if minutes > 0
        builder << "#{seconds}S" if seconds > 0
        builder.join
      end

      private

      def time?
        hours > 0 || minutes > 0 || seconds > 0
      end

      DURATION_PAST_REGEX = /\A([+-])P/.freeze
      DURATION_WEEKS_REGEX = /(\d+)W/.freeze
      DURATION_DAYS_REGEX = /(\d+)D/.freeze
      DURATION_HOURS_REGEX = /(\d+)H/.freeze
      DURATION_MINUTES_REGEX = /(\d+)M/.freeze
      DURATION_SECONDS_REGEX = /(\d+)S/.freeze

      def parse_fields(value)
        {
          past: (value =~ DURATION_PAST_REGEX ? $1 == '-' : false),
          weeks: (value =~ DURATION_WEEKS_REGEX ? $1.to_i : 0),
          days: (value =~ DURATION_DAYS_REGEX ? $1.to_i : 0),
          hours: (value =~ DURATION_HOURS_REGEX ? $1.to_i : 0),
          minutes: (value =~ DURATION_MINUTES_REGEX ? $1.to_i : 0),
          seconds: (value =~ DURATION_SECONDS_REGEX ? $1.to_i : 0)
        }
      end
    end

  end
end
