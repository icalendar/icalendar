require 'icalendar/logger'

module Icalendar

  MAX_LINE_LENGTH = 75

  def self.logger
    @logger ||= Icalendar::Logger.new(STDERR)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.parse(source, single = false)
    calendars_or_events = Parser.new(source).parse
    single ? calendars_or_events.first : calendars_or_events
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
