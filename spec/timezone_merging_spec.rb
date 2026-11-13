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
        DateTime.new(2007, 3, 20, 12), # daylight under new rules, standard under old
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

describe 'TZInfo::Timezone#ical_timezone_for_range' do
  def round_trip(timezone)
    calendar = Icalendar::Calendar.new
    calendar.add_component timezone
    Icalendar::Calendar.parse(calendar.to_ical).first.timezones.first
  end

  def expect_offsets_to_match_tzinfo(tzinfo, timezone, local_times)
    local_times.each do |local|
      expected = tzinfo.period_for_local(local).offset.ical_offset
      expect(timezone.offset_for_local(local).value_ical).to eq(expected), "#{tzinfo.identifier} at #{local}"
    end
  end

  def monthly(first, last)
    (first.year..last.year).flat_map do |year|
      (1..12).flat_map { |month| [DateTime.new(year, month, 1, 12), DateTime.new(year, month, 15, 12)] }
    end.select { |local| local >= first && local <= last }
  end

  it 'matches ical_timezone when both dates are in the same period' do
    tz = TZInfo::Timezone.get 'Europe/Brussels'
    expect(tz.ical_timezone_for_range(DateTime.new(2021, 4, 1), DateTime.new(2021, 9, 1)).to_ical)
      .to eq tz.ical_timezone(DateTime.new(2021, 9, 1)).to_ical
  end

  it 'accepts the dates in either order' do
    tz = TZInfo::Timezone.get 'America/New_York'
    expect(tz.ical_timezone_for_range(DateTime.new(2008, 7, 1), DateTime.new(2006, 7, 1)).to_ical)
      .to eq tz.ical_timezone_for_range(DateTime.new(2006, 7, 1), DateTime.new(2008, 7, 1)).to_ical
  end

  it 'records the range it was generated for' do
    tz = TZInfo::Timezone.get 'America/New_York'
    source = tz.ical_timezone_for_range(DateTime.new(2006, 7, 1), DateTime.new(2008, 7, 1)).tzinfo_source
    expect(source.identifier).to eq 'America/New_York'
    expect([source.first, source.last]).to eq [DateTime.new(2006, 7, 1), DateTime.new(2008, 7, 1)]
  end

  context 'when a recurring rule ends east of UTC' do
    # Sydney moved from the last Sunday in October to the first Sunday in
    # October in 2008, and had irregular April changes in 2006 and 2008.
    let(:tz) { TZInfo::Timezone.get 'Australia/Sydney' }
    let(:first) { DateTime.new 2005, 7, 1, 12 }
    let(:last) { DateTime.new 2010, 7, 1, 12 }
    subject(:timezone) { tz.ical_timezone_for_range first, last }

    it 'bounds the old rule with a UTC UNTIL at its last occurrence' do
      rules = timezone.daylights.flat_map(&:rrule).map(&:value_ical)
      expect(rules).to contain_exactly 'FREQ=YEARLY;BYDAY=1SU;BYMONTH=10',
                                       'FREQ=YEARLY;UNTIL=20071027T160000Z;BYDAY=-1SU;BYMONTH=10'
    end

    it 'describes the correct offsets across the whole range' do
      expect_offsets_to_match_tzinfo tz, round_trip(timezone), monthly(DateTime.new(2005, 3, 28), last)
    end
  end

  {
    'America/New_York' => [DateTime.new(2006, 7, 1, 12), DateTime.new(2008, 7, 1, 12)],
    'America/Sao_Paulo' => [DateTime.new(2017, 12, 1, 12), DateTime.new(2020, 7, 1, 12)],
    'Europe/Brussels' => [DateTime.new(2015, 1, 15, 12), DateTime.new(2025, 12, 15, 12)],
    'America/Santiago' => [DateTime.new(2014, 1, 15, 12), DateTime.new(2024, 1, 15, 12)]
  }.each do |identifier, (first, last)|
    it "describes the correct offsets for #{identifier} from #{first.year} to #{last.year}" do
      tz = TZInfo::Timezone.get identifier
      start = tz.period_for_local(first).start_transition.local_end_at.to_datetime + 1
      expect_offsets_to_match_tzinfo tz, round_trip(tz.ical_timezone_for_range(first, last)), monthly(start, last)
    end
  end
end

describe Icalendar::Calendar, '#add_timezone' do
  let(:calendar) { described_class.new }
  let(:new_york) { TZInfo::Timezone.get 'America/New_York' }

  def hand_built(tzid, dtstart)
    Icalendar::Timezone.new.tap do |tz|
      tz.tzid = tzid
      tz.standard do |s|
        s.dtstart = dtstart
        s.tzoffsetfrom = '+0100'
        s.tzoffsetto = '+0100'
        s.tzname = 'XST'
      end
    end
  end

  it 'returns the timezone the other was merged into' do
    first = calendar.add_timezone new_york.ical_timezone(DateTime.new(2006, 7, 1))
    expect(calendar.add_timezone(new_york.ical_timezone(DateTime.new(2008, 7, 1)))).to equal first
    expect(calendar.timezones).to eq [first]
  end

  it 'finds the merged timezone by TZID' do
    calendar.add_timezone new_york.ical_timezone(DateTime.new(2006, 7, 1))
    calendar.add_timezone new_york.ical_timezone(DateTime.new(2008, 7, 1))
    found = calendar.find_timezone 'America/New_York'
    expect(found.tzinfo_source.first).to eq DateTime.new(2006, 7, 1)
    expect(found.tzinfo_source.last).to eq DateTime.new(2008, 7, 1)
    expect(found.daylights.length).to eq 2
  end

  it 'merges timezones built with a block' do
    calendar.timezone { |tz| tz.tzid = 'Custom/Zone'; tz.add_component hand_built('x', '19700101T000000').standards.first }
    calendar.timezone { |tz| tz.tzid = 'Custom/Zone'; tz.add_component hand_built('x', '19800101T000000').standards.first }
    expect(calendar.timezones.length).to eq 1
    expect(calendar.timezones.first.standards.length).to eq 2
  end

  it 'combines the observances of hand-built timezones that share a TZID' do
    first = calendar.add_timezone hand_built('Custom/Zone', '19700101T000000')
    calendar.add_timezone hand_built('Custom/Zone', '19800101T000000')
    calendar.add_timezone hand_built('Custom/Zone', '19700101T000000')
    expect(calendar.timezones).to eq [first]
    expect(first.standards.map { |s| s.dtstart.value_ical }).to eq %w[19700101T000000 19800101T000000]
    expect(first.standards.map(&:parent)).to all equal(first)
  end

  it 'combines a TZInfo timezone with a hand-built one that shares its TZID' do
    generated = calendar.add_timezone new_york.ical_timezone(DateTime.new(2008, 7, 1))
    calendar.add_timezone hand_built('America/New_York', '19700101T000000')
    expect(calendar.timezones).to eq [generated]
    expect(generated.standards.length).to eq 2
    expect(generated.tzinfo_source).to be_nil
  end

  it 'does not merge timezones added with add_component' do
    calendar.add_component new_york.ical_timezone(DateTime.new(2006, 7, 1))
    calendar.add_component new_york.ical_timezone(DateTime.new(2008, 7, 1))
    expect(calendar.timezones.length).to eq 2
  end

  it 'does not merge timezones appended to timezones' do
    calendar.timezones << new_york.ical_timezone(DateTime.new(2006, 7, 1))
    calendar.timezones << new_york.ical_timezone(DateTime.new(2008, 7, 1))
    expect(calendar.timezones.length).to eq 2
  end

  it 'does not merge duplicate VTIMEZONEs when parsing' do
    calendar.add_component new_york.ical_timezone(DateTime.new(2006, 7, 1))
    calendar.add_component new_york.ical_timezone(DateTime.new(2008, 7, 1))
    expect(described_class.parse(calendar.to_ical).first.timezones.length).to eq 2
  end

  it 'survives marshalling with its TZInfo source' do
    calendar.add_timezone new_york.ical_timezone(DateTime.new(2006, 7, 1))
    loaded = Marshal.load(Marshal.dump(calendar))
    loaded.add_timezone new_york.ical_timezone(DateTime.new(2008, 7, 1))
    expect(loaded.timezones.length).to eq 1
    expect(loaded.timezones.first.daylights.length).to eq 2
  end
end
