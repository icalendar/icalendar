require 'spec_helper'
require_relative '../lib/icalendar/tzinfo'

# Adding the same timezone more than once (for example, once per event) should
# still produce a single VTIMEZONE per TZID when the calendar is serialized.
# When the timezone's rules differ across the added dates, that single
# VTIMEZONE should hold multiple DAYLIGHT/STANDARD observances covering them.
describe 'Generating a calendar with a timezone added multiple times' do
  let(:calendar) { Icalendar::Calendar.new }

  def add_timezone(identifier, date)
    calendar.add_timezone TZInfo::Timezone.get(identifier).ical_timezone(date)
  end

  def output
    calendar.to_ical
  end

  def vtimezone_count
    output.scan(/^BEGIN:VTIMEZONE\r$/).length
  end

  def tzid_lines
    output.scan(/^TZID:.*\r$/).map(&:chomp)
  end

  def parsed_timezones
    Icalendar::Calendar.parse(output).first.timezones
  end

  def parsed_timezone(identifier)
    parsed_timezones.find { |tz| tz.tzid.to_s == identifier }
  end

  # Counted across every VTIMEZONE with the TZID so that duplicated
  # VTIMEZONEs are not hidden by only looking at the first one.
  def daylights(identifier)
    parsed_timezones.select { |tz| tz.tzid.to_s == identifier }.flat_map(&:daylights)
  end

  def standards(identifier)
    parsed_timezones.select { |tz| tz.tzid.to_s == identifier }.flat_map(&:standards)
  end

  # The merged VTIMEZONE must still describe the correct UTC offset at each of
  # the local times it was generated for.
  def expect_offsets_to_match_tzinfo(identifier, local_times)
    tzinfo = TZInfo::Timezone.get identifier
    timezone = parsed_timezone identifier
    local_times.each do |local|
      expected = tzinfo.period_for_local(local).offset.ical_offset
      offset = timezone.offset_for_local(local)
      # offset_for_local returns the String "+00:00" when no observance applies
      actual = offset.respond_to?(:value_ical) ? offset.value_ical : offset.delete(':')
      expect(actual).to eq(expected), "#{identifier} at #{local}: expected #{expected}, got #{actual}"
    end
  end

  context 'when the same timezone is added twice for the same date' do
    let(:date) { DateTime.new 2021, 1, 15 }

    before do
      add_timezone 'Europe/Brussels', date
      add_timezone 'Europe/Brussels', date
    end

    it 'outputs a single VTIMEZONE' do
      expect(vtimezone_count).to eq 1
      expect(tzid_lines).to eq ['TZID:Europe/Brussels']
    end

    it 'outputs a single daylight and standard observance' do
      expect(daylights('Europe/Brussels').length).to eq 1
      expect(standards('Europe/Brussels').length).to eq 1
    end
  end

  context 'when the same Timezone object is added twice' do
    before do
      timezone = TZInfo::Timezone.get('Europe/Brussels').ical_timezone(DateTime.new(2021, 1, 15))
      calendar.add_timezone timezone
      calendar.add_timezone timezone
    end

    it 'outputs a single VTIMEZONE' do
      expect(vtimezone_count).to eq 1
    end
  end

  context 'when the timezone is added for dates in different years with the same rules' do
    # The reproduction from issue #205
    let(:dates) { [DateTime.new(2019, 3, 1, 12), DateTime.new(2019, 3, 1, 12) + 356] }

    before do
      dates.each { |date| add_timezone 'Europe/Brussels', date }
    end

    it 'outputs a single VTIMEZONE' do
      expect(vtimezone_count).to eq 1
      expect(tzid_lines).to eq ['TZID:Europe/Brussels']
    end

    it 'does not duplicate observances that share the same recurrence rule' do
      expect(daylights('Europe/Brussels').length).to eq 1
      expect(standards('Europe/Brussels').length).to eq 1
    end

    it 'describes the correct offsets for both years' do
      local_times = [2019, 2020].flat_map do |year|
        [DateTime.new(year, 1, 15, 12), DateTime.new(year, 7, 15, 12), DateTime.new(year, 12, 15, 12)]
      end
      expect_offsets_to_match_tzinfo 'Europe/Brussels', local_times
    end
  end

  context 'when the timezone is added for the start and end of many events' do
    let(:starts) do
      [DateTime.new(2025, 9, 4, 12, 51, 24), DateTime.new(2025, 11, 28, 12, 51, 24),
       DateTime.new(2026, 2, 28, 12, 51, 24), DateTime.new(2026, 5, 28, 12, 51, 24),
       DateTime.new(2026, 8, 28, 12, 51, 24)]
    end

    before do
      starts.each do |start|
        finish = start + Rational(2, 24)
        add_timezone 'Europe/Berlin', start
        add_timezone 'Europe/Berlin', finish
        calendar.event do |e|
          e.dtstart = Icalendar::Values::DateTime.new start, 'tzid' => 'Europe/Berlin'
          e.dtend = Icalendar::Values::DateTime.new finish, 'tzid' => 'Europe/Berlin'
        end
      end
    end

    it 'outputs a single VTIMEZONE' do
      expect(vtimezone_count).to eq 1
      expect(tzid_lines).to eq ['TZID:Europe/Berlin']
    end

    it 'still outputs every event' do
      expect(output.scan(/^BEGIN:VEVENT\r$/).length).to eq starts.length
    end

    it 'describes the correct offset for every event' do
      expect_offsets_to_match_tzinfo 'Europe/Berlin', starts
    end
  end

  context 'when the timezone rules change between the added dates' do
    # The US moved its DST transitions in 2007:
    #   2006: first Sunday in April -> last Sunday in October
    #   2008: second Sunday in March -> first Sunday in November
    let(:dates) { [DateTime.new(2006, 7, 1, 12), DateTime.new(2008, 7, 1, 12)] }

    before do
      dates.each { |date| add_timezone 'America/New_York', date }
    end

    it 'outputs a single VTIMEZONE' do
      expect(vtimezone_count).to eq 1
      expect(tzid_lines).to eq ['TZID:America/New_York']
    end

    it 'includes multiple daylight and standard observances' do
      timezone = parsed_timezones.first
      expect(timezone.daylights.length).to be >= 2
      expect(timezone.standards.length).to be >= 2
    end

    it 'describes the correct offsets under both sets of rules' do
      local_times = [
        DateTime.new(2006, 3, 20, 12), # standard under old rules, daylight under new
        DateTime.new(2006, 7, 1, 12),
        DateTime.new(2006, 11, 1, 12), # standard under old rules, daylight under new
        DateTime.new(2008, 3, 20, 12),
        DateTime.new(2008, 7, 1, 12),
        DateTime.new(2008, 11, 1, 12)
      ]
      expect_offsets_to_match_tzinfo 'America/New_York', local_times
    end

    it 'does not depend on the order the timezones were added' do
      reversed = Icalendar::Calendar.new
      dates.reverse_each do |date|
        reversed.add_timezone TZInfo::Timezone.get('America/New_York').ical_timezone(date)
      end
      expect(reversed.to_ical.scan(/^BEGIN:VTIMEZONE\r$/).length).to eq 1
    end
  end

  context 'when daylight saving time is abolished between the added dates' do
    # Brazil stopped observing DST in 2019
    let(:dates) { [DateTime.new(2018, 12, 1, 12), DateTime.new(2020, 7, 1, 12)] }

    before do
      dates.each { |date| add_timezone 'America/Sao_Paulo', date }
    end

    it 'outputs a single VTIMEZONE' do
      expect(vtimezone_count).to eq 1
      expect(tzid_lines).to eq ['TZID:America/Sao_Paulo']
    end

    it 'describes the correct offsets before and after the change' do
      local_times = [DateTime.new(2018, 12, 1, 12), DateTime.new(2020, 1, 15, 12), DateTime.new(2020, 7, 1, 12)]
      expect_offsets_to_match_tzinfo 'America/Sao_Paulo', local_times
    end
  end

  context 'when a timezone without daylight saving time is added twice' do
    before do
      add_timezone 'Asia/Tokyo', DateTime.new(2020, 1, 15)
      add_timezone 'Asia/Tokyo', DateTime.new(2021, 7, 15)
    end

    it 'outputs a single VTIMEZONE with a single standard observance' do
      expect(vtimezone_count).to eq 1
      expect(standards('Asia/Tokyo').length).to eq 1
      expect(daylights('Asia/Tokyo')).to be_empty
    end
  end

  context 'when multiple different timezones are each added multiple times' do
    before do
      add_timezone 'Europe/Brussels', DateTime.new(2021, 1, 15)
      add_timezone 'America/Chicago', DateTime.new(2021, 1, 15)
      add_timezone 'Europe/Brussels', DateTime.new(2022, 7, 15)
      add_timezone 'America/Chicago', DateTime.new(2022, 7, 15)
      add_timezone 'Europe/Brussels', DateTime.new(2021, 1, 15)
    end

    it 'outputs one VTIMEZONE per TZID' do
      expect(vtimezone_count).to eq 2
      expect(tzid_lines).to contain_exactly 'TZID:Europe/Brussels', 'TZID:America/Chicago'
    end

    it 'keeps the timezones in the order they were first added' do
      expect(tzid_lines).to eq ['TZID:Europe/Brussels', 'TZID:America/Chicago']
    end
  end
end
