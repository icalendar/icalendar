# frozen_string_literal: true

require 'date'

module Icalendar

  class Calendar < Component
    required_property :version
    required_property :prodid
    optional_single_property :calscale
    optional_single_property :ip_method
    optional_property :ip_name
    optional_property :description
    optional_single_property :uid
    optional_single_property :last_modified, Icalendar::Values::DateTime, true
    optional_single_property :url, Icalendar::Values::Uri, true
    optional_property :categories, Icalendar::Values::Text, false, false, true
    optional_single_property :refresh_interval, Icalendar::Values::Duration, true
    optional_single_property :source, Icalendar::Values::Uri, true
    optional_single_property :color
    optional_property :image, Icalendar::Values::Uri, false, true

    component :timezone, :tzid
    component :event
    component :todo
    component :journal
    component :freebusy

    def initialize
      super 'calendar'
      self.prodid = 'icalendar-ruby'
      self.version = '2.0'
      self.calscale = 'GREGORIAN'
    end

    def publish
      self.ip_method = 'PUBLISH'
      self
    end

    def request
      self.ip_method = 'REQUEST'
      self
    end

    def reply
      self.ip_method = 'REPLY'
      self
    end

    def add
      self.ip_method = 'ADD'
      self
    end

    def cancel
      self.ip_method = 'CANCEL'
      self
    end

    def refresh
      self.ip_method = 'REFRESH'
      self
    end

    def counter
      self.ip_method = 'COUNTER'
      self
    end

    def decline_counter
      self.ip_method = 'DECLINECOUNTER'
      self
    end

    private

    def ical_components_for(component_name)
      return super unless component_name == 'timezones'

      seen = {}
      groups = {}
      records = []
      timezones.each do |timezone|
        serialized = timezone.to_ical
        next if seen[serialized]
        seen[serialized] = true
        parts = mergeable_timezone_parts(timezone, serialized)
        if parts
          key = parts.inject(serialized) { |text, part| text.sub(part[:text]) { part[:key] } }
          if (previous = groups[key])
            parts.each_with_index do |part, index|
              previous[:selected][index] = part if part[:onset] < previous[:selected][index][:onset]
            end
            next
          end
          record = { text: serialized, originals: parts.map { |part| part[:text] }, selected: parts }
          groups[key] = record
        else
          record = { text: serialized, originals: [], selected: [] }
        end
        records << record
      end
      records.map do |record|
        record[:originals].each_with_index.inject(record[:text]) do |text, (original, index)|
          text.sub(original) { record[:selected][index][:text] }
        end
      end
    end

    # Equivalent unbounded yearly rules differ only in their first occurrence.
    # Their union starts at the earliest onset; no recurrence is guessed and no
    # overlapping second rule (or invented UNTIL) needs to be emitted.
    def mergeable_timezone_parts(timezone, serialized)
      return if timezone.daylights.length > 1 || timezone.standards.length > 1
      observances = timezone.daylights + timezone.standards
      return if observances.empty?
      parts = observances.map do |observance|
        return unless observance.rrule.length == 1
        text = observance.to_ical
        return unless serialized.index(text) && serialized.index(text) == serialized.rindex(text)
        matches = text.scan(/\r\nDTSTART:(\d{8}T\d{6})\r\n/)
        return unless matches.length == 1
        onset = matches.first.first
        return unless yearly_timezone_onset?(observance.rrule.first.value_ical, onset)
        { text: text, onset: onset, key: text.sub("DTSTART:#{onset}", "DTSTART:YYYYMMDD#{onset[8..-1]}") }
      end
      parts
    end

    def yearly_timezone_onset?(rule, onset)
      fields = rule.split(';').map { |field| field.split('=', 2) }
      return false unless fields.length == 3 && fields.all? { |field| field.length == 2 }
      fields = fields.to_h
      return false unless fields.keys.sort == ['BYDAY', 'BYMONTH', 'FREQ'] && fields['FREQ'] == 'YEARLY'
      return false unless fields['BYMONTH'].match?(/\A(?:[1-9]|1[0-2])\z/)
      match = /\A(-?[1-5])(SU|MO|TU|WE|TH|FR|SA)\z/.match(fields['BYDAY'])
      return false unless match
      year, month, day = [onset[0, 4], onset[4, 2], onset[6, 2]].map(&:to_i)
      return false unless month == fields['BYMONTH'].to_i
      date = Date.new(year, month, day, Date::GREGORIAN)
      return false unless %w[SU MO TU WE TH FR SA][date.wday] == match[2]
      ordinal = match[1].to_i
      if ordinal > 0
        (day - 1) / 7 + 1 == ordinal
      else
        last_day = Date.new(year, month, -1, Date::GREGORIAN).day
        -((last_day - day) / 7 + 1) == ordinal
      end
    end

  end

end
