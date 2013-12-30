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

require 'icalendar/has_properties'
require 'icalendar/has_components'
require 'icalendar/component'
require 'icalendar/value'
require 'icalendar/alarm'
require 'icalendar/event'
require 'icalendar/todo'
require 'icalendar/journal'
require 'icalendar/freebusy'
require 'icalendar/timezone'
require 'icalendar/calendar'
require 'icalendar/parser'