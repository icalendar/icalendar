module Icalendar

  class Alarm < Component

    required_property :action
    required_property :trigger
    required_property :description, Icalendar::Values::Text,
                      ->(alarm, description) { alarm.action.downcase == 'audio' || !description.nil? }
    required_property :summary, Icalendar::Values::Text,
                      ->(alarm, summary) { alarm.action.downcase != 'email' || !summary.nil? }
    required_multi_property :attendee, Icalendar::Values::Text,
                            ->(alarm, attendees) { alarm.action.downcase != 'email' || !attendees.compact.empty? }

    optional_single_property :duration
    optional_single_property :repeat

    optional_property :attach, Icalendar::Values::Uri

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
      # attach must be single for audio actions
      action.downcase == 'audio' && attach.compact.size > 1 and return false
      super
    end
  end
end