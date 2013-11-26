module Icalendar

  VERSION = '2.0.0'

  def self.parse(source)
    Base.new source
  end

  class Base
    def initialize(source)
      @source = source
    end

    def to_ical
      @source
    end
  end
end

require 'icalendar/properties'
require 'icalendar/components'
require 'icalendar/component'
require 'icalendar/alarm'
require 'icalendar/event'
require 'icalendar/todo'
require 'icalendar/journal'
require 'icalendar/freebusy'
require 'icalendar/timezone'
require 'icalendar/calendar'