# frozen_string_literal: true

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
require_relative 'transition_rule_sample'
require_relative 'timezone_history'
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

    def offset_abbreviation
      offset.abbreviation.to_s
    end

    def rrule
      # RFC 5545 defines the onset in local time using TZOFFSETFROM.
      start = (respond_to?(:local_end_at) ? local_end_at : local_end).to_datetime
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
      (respond_to?(:local_end_at) ? local_end_at : local_end).to_datetime.strftime '%Y%m%dT%H%M%S'
    end
  end

  module TimezoneOffset
    def ical_offset
      o = utc_total_offset
      magnitude = o.abs
      sprintf '%s%02d%02d', o < 0 ? '-' : '+', magnitude / 3600, (magnitude / 60) % 60
    end
  end
end


module TZInfo
  class Timezone
    def ical_timezone(date, dst = Timezone.default_dst)
      local = ical_local(date)
      ical_timezone_for_period(period_for_local(local, dst)).tap do |timezone|
        timezone.tzinfo_source = Icalendar::Timezone::TzinfoSource.new(
          identifier: identifier, first: local, last: local, dst: dst
        )
      end
    end

    def ical_timezone_for_range(first_date, last_date, dst = Timezone.default_dst)
      first, last = [ical_local(first_date), ical_local(last_date)].sort
      timezone = ical_timezone(last, dst)
      timezone.tzinfo_source.first = first

      first_period = period_for_local(first, dst)
      last_period = period_for_local(last, dst)
      return timezone if first_period == last_period || last_period.start_transition.nil?
      # TZInfo 0.3 has no transitions_up_to; only the last period is described.
      return timezone unless respond_to?(:transitions_up_to)

      # Times before the zone's first transition are not described.
      lower = (first_period.start_transition || first_period.end_transition).at
      historic = transitions_up_to(last_period.start_transition.at, lower)
      Icalendar::TimezoneHistory.new(timezone, historic).apply
      timezone
    end

    private

    # Wall-clock local time, without any UTC offset the caller's value carries.
    def ical_local(date)
      date = date.to_datetime
      DateTime.new(date.year, date.month, date.day, date.hour, date.min, date.sec + date.sec_fraction)
    end

    def ical_timezone_for_period(period)
      timezone = Icalendar::Timezone.new
      timezone.tzid = identifier
      if period.start_transition.nil?
        timezone.add_component period.single
      elsif period.end_transition.nil?
        timezone.add_component period.dst? ? period.daylight : period.standard
      else
        daylight = period.daylight
        standard = period.standard
        # TZInfo 0.3 has no transitions_up_to; retain its existing behavior.
        if respond_to?(:transitions_up_to)
          anchors = [period.dst? ? period.start_transition : period.end_transition,
                     period.dst? ? period.end_transition : period.start_transition]
          first_year = anchors.map { |anchor| Icalendar::TransitionRuleSample.onset(anchor).year }.min
          # Away from non-leap century years, weekday/leap-year patterns repeat
          # every 28 years. This bounded sample does not predict timezone-law
          # changes; window rules still require all seven monthday outcomes.
          year_count = 28
          # transitions_up_to takes UTC bounds, while recurrence onsets use the
          # previous offset's local time. Pad the query to include onsets near
          # local New Year, then discard only the padding outside our local years.
          transitions = transitions_up_to(Time.utc(first_year + year_count, 1, 3),
                                          Time.utc(first_year - 1, 12, 30))
          transitions = transitions.select do |transition|
            year = Icalendar::TransitionRuleSample.onset(transition).year
            year >= first_year && year < first_year + year_count
          end
          rules = Icalendar::TransitionRuleSample.rules(transitions, anchors, first_year, year_count)
          if rules
            daylight.rrule = rules[0]
            standard.rrule = rules[1]
          end
        end
        timezone.add_component daylight
        timezone.add_component standard
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

    # For DST, use the start_transition,
    # for standard TZ, use the following period (starting from the end_transition).
    def daylight
      transition = dst? ? start_transition : end_transition
      day = Icalendar::Timezone::Daylight.new
      build_timezone(day, transition) do |tz|
        # rrule should not be set for the current [==DST/daylight] period
        # if there is no recurrence rule for the end transition
        if !dst? || !end_transition.nil?
          tz.rrule = transition.rrule
        end
      end
    end

    # For standard TZ, use the start_transition,
    # for DST, use the following period, (starting from the end_transition)
    def standard
      transition = dst? ? end_transition : start_transition
      std = Icalendar::Timezone::Standard.new
      build_timezone(std, transition) do |tz|
        if dst? || !end_transition.nil?
          tz.rrule = transition.rrule
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

    private
    def build_timezone(timezone, transition)
      timezone.tap do |tz|
        tz.tzname = transition.offset_abbreviation
        tz.tzoffsetfrom = transition.offset_from
        tz.tzoffsetto = transition.offset_to
        tz.dtstart = transition.dtstart
        yield tz
      end
    end
  end
end
