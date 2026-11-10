# frozen_string_literal: true

module Icalendar
  # Conservative internal inference for stable, twice-yearly transitions.
  # This is evidence from the installed timezone data, not a prediction of law.
  class TransitionRuleSample
    def self.onset(transition)
      (transition.respond_to?(:local_end_at) ? transition.local_end_at : transition.local_end).to_datetime
    end

    def self.signature(transition)
      date = onset(transition)
      [date.month, date.wday, date.hour, date.min, date.sec, date.sec_fraction,
       transition.previous_offset.utc_total_offset, transition.offset.utc_total_offset]
    end

    def self.rules(transitions, anchors, first_year, year_count)
      years = (first_year...(first_year + year_count)).to_a
      # Do not discard transitions with unexpected offsets, months or clocks.
      # Every transition in the complete local-year interval must be accounted for.
      grouped = transitions.group_by { |transition| onset(transition).year }
      return unless grouped.keys.sort == years
      return unless grouped.values.all? { |items| items.length == 2 }
      signatures = anchors.map { |anchor| signature(anchor) }
      return unless signatures.uniq.length == 2
      return unless signatures[0][-2, 2] == signatures[1][-2, 2].reverse
      return if signatures[0][-2] == signatures[0][-1]
      return unless grouped.values.all? { |items| items.map { |item| signature(item) }.sort == signatures.sort }

      rules = anchors.map do |anchor|
        dates = years.map do |year|
          onset(grouped.fetch(year).find { |item| signature(item) == signature(anchor) })
        end
        start = onset(anchor)
        week_number = (start.day - 1) / 7 + 1
        week_number = -1 if week_number > 3
        ordinal_days = years.map do |year|
          days = (1..Date.new(year, start.month, -1).day).select do |day|
            Date.new(year, start.month, day).wday == start.wday
          end
          days[week_number == -1 ? -1 : week_number - 1]
        end
        if dates.map(&:day) == ordinal_days
          anchor.rrule
        else
          days = dates.map(&:day).uniq.sort
          # Seeing all seven outcomes avoids inferring a window from sparse data.
          return unless days.length == 7 && days == (days.first..(days.first + 6)).to_a
          # Matching signatures already fix the month and weekday for every
          # date. Seven consecutive observed monthdays therefore identify the
          # unique matching weekday in the window for every sampled year.
          ["FREQ=YEARLY;BYMONTH=#{start.month};BYDAY=#{start.strftime('%a').upcase[0, 2]};BYMONTHDAY=#{days.join(',')}"]
        end
      end
      rules
    end
  end
end
