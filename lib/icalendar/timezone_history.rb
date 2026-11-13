# frozen_string_literal: true

require 'ice_cube'

module Icalendar
  # Adds the observances for a list of historic TZInfo transitions to a
  # timezone whose current (indefinitely recurring) observances are already
  # built.
  #
  # Transitions are walked newest to oldest. A transition that is the previous
  # occurrence of a recurring observance of the same kind, with the same
  # offsets and name, moves that observance's DTSTART back to it. Any other
  # transition starts a new observance. Observances started this way recur
  # only until the last transition they cover, or not at all when they cover
  # a single transition.
  class TimezoneHistory
    Run = Struct.new(:observance, :onset, :latest, :count, keyword_init: true)

    def initialize(timezone, transitions)
      @timezone = timezone
      @transitions = transitions
    end

    def apply
      open = {}
      @timezone.daylights.each { |observance| open[:daylight] = current_run(observance) }
      @timezone.standards.each { |observance| open[:standard] = current_run(observance) }
      historic = []

      @transitions.reverse_each do |transition|
        kind = transition.offset.dst? ? :daylight : :standard
        run = open[kind]
        if run && extends?(run, transition)
          run.observance.dtstart = transition.dtstart
          run.onset = TransitionRuleSample.onset(transition)
          run.count += 1
        else
          run = Run.new(observance: observance_for(kind, transition), onset: TransitionRuleSample.onset(transition),
                        latest: transition, count: 1)
          open[kind] = run
          historic << run
        end
      end

      historic.reverse_each do |run|
        observance = run.observance
        observance.rrule = if run.count == 1
          []
        else
          "#{observance.rrule.first.value_ical};UNTIL=#{run.latest.at.to_time.utc.strftime('%Y%m%dT%H%M%SZ')}"
        end
        @timezone.add_component observance
      end
    end

    private

    def current_run(observance)
      return if observance.rrule.empty?
      Run.new(observance: observance, onset: observance.dtstart.value.to_datetime, count: 1)
    end

    def observance_for(kind, transition)
      observance = kind == :daylight ? Timezone::Daylight.new : Timezone::Standard.new
      observance.tzname = transition.offset_abbreviation
      observance.tzoffsetfrom = transition.offset_from
      observance.tzoffsetto = transition.offset_to
      observance.dtstart = transition.dtstart
      observance.rrule = transition.rrule
      observance
    end

    # Whether this transition is an occurrence of the observance's rule, and
    # the rule's next occurrence after it is the observance's current DTSTART.
    def extends?(run, transition)
      observance = run.observance
      return false unless observance.tzoffsetfrom.value_ical == transition.offset_from &&
                          observance.tzoffsetto.value_ical == transition.offset_to &&
                          observance.tzname.first.to_s == transition.offset_abbreviation

      onset = floating_time(TransitionRuleSample.onset(transition))
      # IceCube always yields the schedule start, so start the schedule before
      # the onset's year at the onset's clock time and look at what follows.
      start = Time.utc(onset.year - 1, 12, 31, onset.hour, onset.min, onset.sec)
      schedule = IceCube::Schedule.new(start)
      schedule.add_recurrence_rule IceCube::Rule.from_ical(observance.rrule.first.value_ical)
      schedule.next_occurrences(2, start) == [onset, floating_time(run.onset)]
    end

    def floating_time(datetime)
      Time.utc(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
    end
  end
end
