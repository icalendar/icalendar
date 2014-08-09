=begin
  Copyright (C) 2008 Sean Dague

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

# The following adds a bunch of mixins to the tzinfo class, with the
# intent on making it very easy to load in tzinfo data for generating
# ical events.  With this you can do the following:
#
#   require "icalendar/tzinfo"
#
#   estart = DateTime.new(2008, 12, 29, 8, 0, 0)
#   eend = DateTime.new(2008, 12, 29, 11, 0, 0)
#   tstring = "America/Chicago"
#
#   tz = TZInfo::Timezone.get(tstring)
#   cal = Calendar.new
#   # the mixins now generate all the timezone info for the date in question
#   timezone = tz.ical_timezone(estart)
#   cal.add(timezone)
#
#   cal.event do
#       dtstart       estart
#       dtend        eend
#       summary     "Meeting with the man."
#       description "Have a long lunch meeting and decide nothing..."
#       klass       "PRIVATE"
#   end
#
#   puts cal.to_ical
#
# The recurance rule calculations are hacky, and only start at the
# beginning of the current dst transition.  I doubt this works for non
# dst areas yet.  However, for a standard dst flipping zone, this
# seems to work fine (tested in Mozilla Thunderbird + Lightning).
# Future goal would be making this better.


require 'tzinfo'
begin
  require 'tzinfo/data'
rescue LoadError
  Icalendar.logger.info "Could not load tzinfo/data, hopefully tzinfo is accurate (ignore for tzinfo 0.x)"
end

module Icalendar
  module TimezoneTransition
    def offset_from
      previous_offset.ical_offset
    end

    def offset_to
      offset.ical_offset
    end

    def rrule
      start = local_start.to_datetime
      # this is somewhat of a hack, but seems to work ok
      # assumes that no timezone transition is in law as "4th X of the month"
      # but only as 1st X, 2nd X, 3rd X, or Last X
      start_week = ((start.day - 1) / 7).to_i + 1
      start_week = (start_week > 3) ? -1 : start_week
      [sprintf(
        'FREQ=YEARLY;BYMONTH=%d;BYDAY=%d%s',
        start.month,
        start_week,
        start.strftime('%a').upcase[0,2]
      )]
    end

    def dtstart
      local_start.to_datetime.strftime '%Y%m%dT%H%M%S'
    end
  end

  module TimezoneOffset
    def ical_offset
      o = utc_total_offset
      sprintf '%+-2.2d%2.2d', (o / 3600).to_i, ((o / 60) % 60).to_i
    end
  end
end


module TZInfo
  class Timezone
    def ical_timezone(date, dst = Timezone.default_dst)
      period = period_for_local(date, dst)
      timezone = Icalendar::Timezone.new
      timezone.tzid = identifier
      if period.start_transition.nil?
        timezone.add_component period.single
      elsif period.end_transition.nil?
        timezone.add_component period.dst? ? period.daylight : period.standard
      else
        timezone.add_component period.daylight
        timezone.add_component period.standard
      end
      timezone
    end
  end

  if defined? TimezoneTransitionInfo
    class TimezoneTransitionInfo
      include Icalendar::TimezoneTransition
    end
  else
    class TimezoneTransition
      include Icalendar::TimezoneTransition
    end
  end

  if defined? TimezoneOffsetInfo
    class TimezoneOffsetInfo
      include Icalendar::TimezoneOffset
    end
  else
    class TimezoneOffset
      include Icalendar::TimezoneOffset
    end
  end

  class TimezonePeriod
    def daylight
      Icalendar::Timezone::Daylight.new.tap do |day|
        if dst?
          day.tzname = abbreviation.to_s
          day.tzoffsetfrom = start_transition.offset_from
          day.tzoffsetto = start_transition.offset_to
          day.dtstart = start_transition.dtstart
          day.rrule = start_transition.rrule unless end_transition.nil?
        else
          day.tzname = abbreviation.to_s.sub("ST","DT")
          day.tzoffsetfrom = end_transition.offset_from
          day.tzoffsetto = end_transition.offset_to
          day.dtstart = end_transition.dtstart
          day.rrule = end_transition.rrule
        end
      end
    end

    def standard
      Icalendar::Timezone::Standard.new.tap do |std|
        if dst?
          std.tzname = abbreviation.to_s.sub('DT', 'ST')
          std.tzoffsetfrom = end_transition.offset_from
          std.tzoffsetto = end_transition.offset_to
          std.dtstart = end_transition.dtstart
          std.rrule = end_transition.rrule
        else
          std.tzname = abbreviation.to_s
          std.tzoffsetfrom = start_transition.offset_from
          std.tzoffsetto = start_transition.offset_to
          std.dtstart = start_transition.dtstart
          std.rrule = start_transition.rrule unless end_transition.nil?
        end
      end
    end

    def single
      Icalendar::Timezone::Standard.new.tap do |std|
        std.tzname = abbreviation.to_s
        std.tzoffsetfrom = offset.ical_offset
        std.tzoffsetto = offset.ical_offset
        std.dtstart = DateTime.new(1970).strftime '%Y%m%dT%H%M%S'
      end
    end
  end
end
