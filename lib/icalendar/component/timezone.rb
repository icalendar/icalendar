=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end
module Icalendar
  # A Timezone is unambiguously defined by the set of time
  # measurement rules determined by the governing body for a given
  # geographic area. These rules describe at a minimum the base offset
  # from UTC for the time zone, often referred to as the Standard Time
  # offset. Many locations adjust their Standard Time forward or backward
  # by one hour, in order to accommodate seasonal changes in number of
  # daylight hours, often referred to as Daylight  Saving Time. Some
  # locations adjust their time by a fraction of an hour. Standard Time
  # is also known as Winter Time. Daylight Saving Time is also known as
  # Advanced Time, Summer Time, or Legal Time in certain countries. The
  # following table shows the changes in time zone rules in effect for
  # New York City starting from 1967. Each line represents a description
  # or rule for a particular observance.
  class Timezone < Component
    # Single properties
    ical_property :dtstart, :start
    ical_property :tzoffsetto, :timezone_offset_to
    ical_property :tzoffsetfrom, :timezone_offset_from
    ical_property :tzid, :timezone_id
    ical_property :tzname, :timezone_name
    ical_property :tzurl, :timezone_url

    ical_property :created
    ical_property :last_modified
    ical_property :timestamp
    ical_property :sequence

    # Multi-properties
    ical_multi_property :comment, :comment, :comments
    ical_multi_property :rdate, :recurrence_date, :recurrence_dates
    ical_multi_property :rrule, :recurrence_rule, :recurrence_rules

    # Define a custom add component method because standard and daylight
    # are the only components that can occur just once with their parent.
    def add_component(component)
      key = component.class.to_s.downcase.gsub('icalendar::','').to_sym
      @components[key] = component
    end

    def initialize(name = "VTIMEZONE")
      super(name)
    end

    # Allow block syntax for declaration of standard and daylight components of timezone
    def standard(&block)
      e = Standard.new
      self.add_component e

      e.instance_eval(&block) if block

      e
    end

    def daylight(&block)
      e = Daylight.new
      self.add_component e

      e.instance_eval(&block) if block

      e
    end
  end

  # A Standard component is a sub-component of the Timezone component which
  # is used to describe the standard time offset.
  class Standard < Timezone

    def initialize()
      super("STANDARD")
    end
  end

  # A Daylight component is a sub-component of the Timezone component which
  # is used to describe the time offset for what is commonly known as
  # daylight savings time.
  class Daylight < Timezone

    def initialize()
      super("DAYLIGHT")
    end
  end

end
