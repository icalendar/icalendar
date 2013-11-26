module Icalendar

  class Alarm < Component

    required_property :action
    required_property :trigger
    required_property :description, ->(alarm, description) { alarm.action.downcase == 'audio' || !description.nil? }
    required_property :summary, ->(alarm, summary) { alarm.action.downcase != 'email' || !summary.nil? }
    required_multi_property :attendee, ->(alarm, attendees) { alarm.action.downcase != 'email' || !attendees.compact.empty? }

    optional_single_property :duration
    optional_single_property :repeat
    optional_single_property :attach

    def initialize
      super 'alarm'
    end

    def valid?(strict = false)
      if strict
        # must be part of event or todo
        !(parent.nil? || parent.name == 'event' || parent.name == 'todo') and return false
      end
      # either both duration and repeat or neither should be set
      [duration, repeat].compact.size == 1 and return false
      super
    end
  end
end