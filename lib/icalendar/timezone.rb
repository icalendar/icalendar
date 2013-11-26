module Icalendar

  class Timezone < Component
    module TzProperties
      def self.included(base)
        base.class_eval do
          required_property :dtstart
          required_property :tzoffsetto
          required_property :tzoffsetfrom

          optional_property :rrule, true
          optional_property :comment
          optional_property :rdate
          optional_property :tzname
        end
      end
    end
    class Daylight < Component
      include TzProperties

      def initialize
        super 'daylight', 'DAYLIGHT'
      end
    end
    class Standard < Component
      include TzProperties

      def initialize
        super 'standard', 'STANDARD'
      end
    end


    required_property :tzid

    optional_single_property :last_mod
    optional_single_property :tzurl

    component :daylight, false, Icalendar::Timezone::Daylight
    component :standard, false, Icalendar::Timezone::Standard

    def initialize
      super 'timezone'
    end

    def valid?(strict = false)
      daylights.empty? && standards.empty? and return false
      daylights.all? { |d| d.valid? strict } or return false
      standards.all? { |s| s.valid? strict } or return false
      super
    end
  end
end