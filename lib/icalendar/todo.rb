module Icalendar

  class Todo < Component
    required_property :dtstamp
    required_property :uid
    # dtstart only required if duration is specified
    required_property :dtstart, Icalendar::Values::Text,
                      ->(todo, dtstart) { !(!todo.duration.nil? && dtstart.nil?) }

    mutually_exclusive_properties [:due, :duration]

    optional_single_property :ip_class
    optional_single_property :completed
    optional_single_property :created
    optional_single_property :description
    optional_single_property :geo
    optional_single_property :last_mod
    optional_single_property :location
    optional_single_property :organizer
    optional_single_property :percent
    optional_single_property :priority
    optional_single_property :recurrence_id
    optional_single_property :sequence
    optional_single_property :status
    optional_single_property :summary
    optional_single_property :url

    optional_property :rrule, Icalendar::Values::Text, true
    optional_property :attach, Icalendar::Values::Uri
    optional_property :attendee
    optional_property :categories
    optional_property :comment
    optional_property :contact
    optional_property :exdate
    optional_property :rstatus
    optional_property :related
    optional_property :resources
    optional_property :rdate

    component :alarm, false

    def initialize
      super 'todo'
      self.dtstamp = Time.now.utc.to_datetime
      self.uid = new_uid
    end

  end

end