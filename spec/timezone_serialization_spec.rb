require 'spec_helper'
require 'icalendar/tzinfo'

describe 'Calendar timezone serialization' do
  let(:calendar) { Icalendar::Calendar.new }
  let(:brussels) { TZInfo::Timezone.get 'Europe/Brussels' }
  let(:date) { DateTime.new 2021, 1, 15 }

  def add_zone(date)
    calendar.add_timezone brussels.ical_timezone(date)
  end

  def parsed_calendar
    Icalendar::Calendar.parse(calendar.to_ical).first
  end

  it 'serializes identical timezone definitions only once without changing the collection' do
    first = add_zone(date)
    second = add_zone(date)
    original = first.to_ical

    expect(calendar.to_ical.scan('BEGIN:VTIMEZONE').length).to eq 1
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [original]
    expect(calendar.timezones).to eq [first, second]
    expect(first.parent).to equal calendar
    expect(second.parent).to equal calendar
    expect(first.to_ical).to eq original
    expect(second.to_ical).to eq original
  end

  it 'also coalesces repeated references to the same timezone' do
    zone = add_zone(date)
    calendar.add_timezone zone

    expect(parsed_calendar.timezones.length).to eq 1
    expect(calendar.timezones).to eq [zone, zone]
  end

  it 'does not cache away changes to a previously identical definition' do
    add_zone(date)
    second = add_zone(date)
    expect(parsed_calendar.timezones.length).to eq 1

    second.tzurl = 'https://example.com/updated-zone'
    expect(parsed_calendar.timezones.length).to eq 2
  end

  def expanded_transitions(zone, first_year, last_year)
    (zone.daylights + zone.standards).flat_map do |observance|
      observance.occurrences.take_while { |onset| onset.year <= last_year }.select { |onset| onset.year >= first_year }.map do |onset|
        [onset.strftime('%Y%m%dT%H%M%S'), observance.tzoffsetfrom.value_ical, observance.tzoffsetto.value_ical]
      end
    end.sort
  end

  def tzinfo_transitions(timezone, first_year, last_year)
    timezone.transitions_up_to(Time.utc(last_year + 1), Time.utc(first_year)).map do |transition|
      [transition.local_end_at.to_datetime.strftime('%Y%m%dT%H%M%S'),
       transition.previous_offset.ical_offset, transition.offset.ical_offset]
    end.sort
  end

  it 'consolidates the original two-year Brussels case with all four distinct transitions' do
    first_date = DateTime.new(2019, 3, 1, 12)
    first = add_zone(first_date)
    second = add_zone(first_date + 356)
    originals = [first.to_ical, second.to_ical]
    expect(originals.uniq.length).to eq 2

    zones = parsed_calendar.timezones
    expect(zones.length).to eq 1
    expect([zones.first.daylights.length, zones.first.standards.length]).to eq [1, 1]
    expect(expanded_transitions(zones.first, 2019, 2020)).to eq tzinfo_transitions(brussels, 2019, 2020)
    expect(expanded_transitions(zones.first, 2019, 2020).length).to eq 4
    expect(zones.first.daylights.first.dtstart.value_ical).not_to end_with 'Z'
    expect(zones.first.standards.first.dtstart.value_ical).not_to end_with 'Z'
    expect(calendar.timezones.map(&:to_ical)).to eq originals
    expect(calendar.to_ical).not_to include 'UNTIL='
  end

  it 'consolidates the multi-event Berlin case without changing event-local dates' do
    berlin = TZInfo::Timezone.get 'Europe/Berlin'
    starts = [DateTime.new(2025, 9, 4, 12, 51, 24), DateTime.new(2025, 11, 28, 12, 51, 24),
              DateTime.new(2026, 2, 28, 12, 51, 24), DateTime.new(2026, 5, 28, 12, 51, 24),
              DateTime.new(2026, 8, 28, 12, 51, 24)]
    starts.each do |start|
      finish = start + Rational(2, 24)
      calendar.add_timezone berlin.ical_timezone(start)
      calendar.add_timezone berlin.ical_timezone(finish)
      calendar.event do |event|
        event.dtstart = Icalendar::Values::DateTime.new start, 'tzid' => 'Europe/Berlin'
        event.dtend = Icalendar::Values::DateTime.new finish, 'tzid' => 'Europe/Berlin'
      end
    end
    event_dates = calendar.events.map { |event| [event.dtstart.to_ical(Icalendar::Values::DateTime), event.dtend.to_ical(Icalendar::Values::DateTime)] }
    parsed = parsed_calendar
    expect(parsed.timezones.length).to eq 1
    expect(calendar.timezones.length).to eq 10
    expect(parsed.events.map { |event| [event.dtstart.to_ical(Icalendar::Values::DateTime), event.dtend.to_ical(Icalendar::Values::DateTime)] }).to eq event_dates
    expect(expanded_transitions(parsed.timezones.first, 2025, 2026)).to eq tzinfo_transitions(berlin, 2025, 2026)
    starts.each do |local|
      expected = berlin.period_for_local(local).offset.ical_offset
      expect(parsed.timezones.first.offset_for_local(local).value_ical).to eq expected
    end
  end

  it 'chooses the earliest onset independently of timezone insertion order' do
    first = add_zone(DateTime.new(2022, 7, 15))
    second = add_zone(date)
    originals = [first.to_ical, second.to_ical]
    zone = parsed_calendar.timezones.first
    expect(parsed_calendar.timezones.length).to eq 1
    expect(zone.daylights.first.dtstart.value_ical).to eq second.daylights.first.dtstart.value_ical
    expect(zone.standards.first.dtstart.value_ical).to eq second.standards.first.dtstart.value_ical
    expect(calendar.timezones.map(&:to_ical)).to eq originals
    expect([first.parent, second.parent]).to eq [calendar, calendar]
  end

  it 'preserves conflicting same-ID offsets rather than merging custom rules' do
    first = add_zone(date)
    second = add_zone(DateTime.new(2022, 1, 15))
    second.daylights.first.tzoffsetto = '+0300'
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
  end

  it 'preserves different clocks and onsets not contained in the common yearly rule' do
    first = add_zone(date)
    second = add_zone(DateTime.new(2022, 1, 15))
    second.daylights.first.dtstart = '20220327T040000'
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]

    second.daylights.first.dtstart = '20220320T020000'
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
  end

  it 'does not infer equivalence for a bounded or different custom recurrence' do
    first = add_zone(date)
    second = add_zone(DateTime.new(2022, 1, 15))
    second.daylights.first.rrule = 'FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU;COUNT=2'
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
    second.daylights.first.rrule = 'FREQ=YEARLY;BYMONTH=3;BYDAY=3SU'
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
  end

  it 'consolidates matching positive ordinal rules without changing their recurrence' do
    first = add_zone(date)
    second = add_zone(DateTime.new(2022, 1, 15))
    [first, second].zip([2021, 2022]).each do |zone, year|
      zone.daylights.first.rrule = 'FREQ=YEARLY;BYMONTH=3;BYDAY=3SU'
      zone.daylights.first.dtstart = year == 2021 ? '20210321T020000' : '20220320T020000'
    end
    zones = parsed_calendar.timezones
    expect(zones.length).to eq 1
    expect(expanded_transitions(zones.first, 2021, 2022)).to eq [
      ['20210321T020000', '+0100', '+0200'], ['20211031T030000', '+0200', '+0100'],
      ['20220320T020000', '+0100', '+0200'], ['20221030T030000', '+0200', '+0100']
    ]
  end

  it 'preserves definitions containing multiple historical observances' do
    first = add_zone(date)
    second = add_zone(DateTime.new(2022, 1, 15))
    [first, second].each do |zone|
      zone.daylight do |historical|
        historical.dtstart = '19960331T020000'
        historical.tzoffsetfrom = '+0100'
        historical.tzoffsetto = '+0200'
        historical.rrule = 'FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU;UNTIL=20000326T010000Z'
      end
    end
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
  end

  it 'preserves fixed zones with no transitions in either requested period' do
    kolkata = TZInfo::Timezone.get 'Asia/Kolkata'
    first = calendar.add_timezone kolkata.ical_timezone(date)
    second = calendar.add_timezone kolkata.ical_timezone(DateTime.new(2022, 7, 15))
    original = first.to_ical
    zone = parsed_calendar.timezones.first
    expect(parsed_calendar.timezones.length).to eq 1
    expect(zone.to_ical).to eq original
    expect(zone.daylights).to be_empty
    expect(zone.standards.first.tzoffsetto.value_ical).to eq '+0530'
    expect(zone.offset_for_local(DateTime.new(2022, 7, 15)).value_ical).to eq '+0530'
    expect(calendar.timezones).to eq [first, second]
  end

  it 'preserves explicit UTC UNTIL boundaries and distinct historical observances' do
    first = add_zone(date)
    first.daylights.first.rrule = 'FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU;UNTIL=20210328T010000Z'
    first.standards.first.rrule = 'FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU;UNTIL=20201025T010000Z'
    second = add_zone(DateTime.new(2022, 1, 15))

    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
    expect(parsed_calendar.timezones.first.daylights.first.rrule.first.until).to eq '20210328T010000Z'
    expect(parsed_calendar.timezones.first.standards.first.rrule.first.until).to eq '20201025T010000Z'
  end

  it 'keeps distinct TZIDs even if their observances are identical' do
    first = add_zone(date)
    second = add_zone(date)
    second.tzid = 'Custom/Brussels'

    expect(parsed_calendar.timezones.map { |zone| zone.tzid.to_s }).to eq ['Europe/Brussels', 'Custom/Brussels']
    expect(parsed_calendar.timezones.map(&:to_ical)).to eq [first.to_ical, second.to_ical]
  end

  it 'preserves the first occurrence order across different timezones' do
    add_zone(date)
    calendar.add_timezone TZInfo::Timezone.get('Asia/Tokyo').ical_timezone(date)
    add_zone(date)

    expect(parsed_calendar.timezones.map { |zone| zone.tzid.to_s }).to eq ['Europe/Brussels', 'Asia/Tokyo']
    expect(parsed_calendar.timezones.last.standards.first.tzoffsetto.value_ical).to eq '+0900'
  end

  it 'retains the winter and summer offsets across year boundaries' do
    add_zone(date)
    add_zone(date)
    zone = parsed_calendar.timezones.first

    [2021, 2022].each do |year|
      [1, 7].each do |month|
        local = DateTime.new(year, month, 15, 12)
        expected = brussels.period_for_local(local).utc_total_offset
        expect(zone.offset_for_local(local).value_ical).to eq sprintf('%+03d00', expected / 3600)
      end
    end
  end

  it 'does not coalesce identical events or custom components' do
    event = calendar.event do |item|
      item.dtstart = '20210115T120000Z'
      item.summary = 'Repeated event'
    end
    calendar.add_event event
    custom = calendar.add_x_example
    custom.x_value = 'keep both'
    calendar.add_x_example custom

    expect(parsed_calendar.events.length).to eq 2
    expect(calendar.to_ical.scan('BEGIN:X_EXAMPLE').length).to eq 2
  end

  # String#sub replacement strings interpret backslashes, even with a literal
  # search string. Compare the emitted bytes before any parser can unescape them.
  ['\\', '\\1', '\\&', '\\`', "\\'", '\\k<name>', '\\' * 4, "comma, semi;\nline"].each do |comment|
    it "preserves escaped observance bytes for one zone: #{comment.inspect}" do
      zone = add_zone(date)
      zone.standards.first.comment = comment
      original = zone.to_ical

      expect(calendar.to_ical).to include original
      expect(parsed_calendar.timezones.first.to_ical).to eq original
      expect(zone.to_ical).to eq original
    end

    it "preserves escaped observance bytes when merging years: #{comment.inspect}" do
      later = add_zone(DateTime.new(2022, 1, 15))
      earlier = add_zone(date)
      [later, earlier].each do |zone|
        zone.daylights.first.comment = comment
        zone.standards.first.comment = comment
      end
      originals = calendar.timezones.map(&:to_ical)

      expect(calendar.to_ical.scan('BEGIN:VTIMEZONE').length).to eq 1
      expect(calendar.to_ical).to include earlier.to_ical
      expect(parsed_calendar.timezones.map(&:to_ical)).to eq [earlier.to_ical]
      expect(calendar.timezones.map(&:to_ical)).to eq originals
    end
  end

  [['\\', '\\' * 4], ["line\nbreak", 'line' + '\\' * 2 + 'nbreak']].each do |comments|
    it "keeps different escaped comments in the grouping key: #{comments.inspect}" do
      first = add_zone(date)
      second = add_zone(DateTime.new(2022, 1, 15))
      [first, second].zip(comments).each { |zone, comment| zone.standards.first.comment = comment }
      originals = [first.to_ical, second.to_ical]

      expect(first.standards.first.comment).not_to eq second.standards.first.comment
      expect(originals.uniq.length).to eq 2
      expect(calendar.to_ical.scan('BEGIN:VTIMEZONE').length).to eq 2
      originals.each { |original| expect(calendar.to_ical).to include original }
      expect(parsed_calendar.timezones.map(&:to_ical)).to eq originals
    end
  end
end
