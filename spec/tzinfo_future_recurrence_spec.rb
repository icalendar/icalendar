require 'spec_helper'
require_relative '../lib/icalendar/tzinfo'

describe 'TZInfo-generated calendar future transition semantics' do
  def round_trip(zone, reference)
    calendar = Icalendar::Calendar.new
    calendar.add_timezone zone.ical_timezone(reference)
    Icalendar::Calendar.parse(calendar.to_ical).first.timezones.first
  end

  [DateTime.new(2026, 10, 7), DateTime.new(2030, 6, 1)].each do |reference|
    [4, 9].each do |month|
      it "preserves Santiago month #{month} boundaries generated on #{reference}" do
        zone = TZInfo::Timezone.get('America/Santiago')
        parsed = round_trip(zone, reference)
        ((reference.year + 1)..(reference.year + 20)).each do |year|
          (1..10).each do |day|
            local = DateTime.new(year, month, day, 12)
            expect(parsed.offset_for_local(local).value_ical).to eq(zone.period_for_local(local).offset.ical_offset),
              "#{reference} -> #{local}: parsed ICS must match TZInfo"
          end
        end
      end
    end
  end

  [[2029, 4, :standards], [2030, 9, :daylights]].each do |year, month, kind|
    it "uses the weekday/monthday intersection in #{year}-#{month}" do
      zone = TZInfo::Timezone.get('America/Santiago')
      parsed = round_trip(zone, DateTime.new(2026, 10, 7))
      component = parsed.public_send(kind).first
      rule = component.rrule.first.value_ical
      expect(rule).to include('BYDAY=SU')
      expect(rule).to include('BYMONTHDAY=2,3,4,5,6,7,8')
      schedule = IceCube::Schedule.new(Time.utc(year, 1, 1))
      schedule.add_recurrence_rule IceCube::Rule.from_ical(rule)
      occurrences = schedule.occurrences_between(Time.utc(year, month, 1), Time.utc(year, month, 10))
      expect(occurrences.map { |time| [time.year, time.month, time.day] }).to eq([[year, month, 8]])
      [1, 7, 8, 9].each do |day|
        local = DateTime.new(year, month, day, 12)
        expect(parsed.offset_for_local(local).value_ical).to eq(zone.period_for_local(local).offset.ical_offset)
      end
    end
  end

  ['Europe/Copenhagen', 'America/Los_Angeles', 'Australia/Lord_Howe'].each do |identifier|
    it "retains onset and adjacent-day behavior for #{identifier}" do
      zone = TZInfo::Timezone.get(identifier)
      generated = zone.ical_timezone(DateTime.new(2026, 1, 1))
      parsed = round_trip(zone, DateTime.new(2026, 1, 1))
      period = zone.period_for_local(DateTime.new(2026, 1, 1))
      [period.start_transition, period.end_transition].each do |transition|
        onset = (transition.respond_to?(:local_end_at) ? transition.local_end_at : transition.local_end).to_datetime
        component = (generated.daylights + generated.standards).find { |item| item.dtstart.value_ical == onset.strftime('%Y%m%dT%H%M%S') }
        expect(component).not_to be_nil
        expect(component.tzoffsetfrom.value_ical).to eq(transition.previous_offset.ical_offset)
        expect(component.tzoffsetto.value_ical).to eq(transition.offset.ical_offset)
      end
      zone.transitions_up_to(Time.utc(2032), Time.utc(2027)).each do |transition|
        onset = (transition.respond_to?(:local_end_at) ? transition.local_end_at : transition.local_end).to_datetime
        [-1, 0, 1].each do |delta|
          date = onset.to_date + delta
          local = DateTime.new(date.year, date.month, date.day, 12)
          expect(parsed.offset_for_local(local).value_ical).to eq(zone.period_for_local(local).offset.ical_offset)
        end
      end
    end
  end

  it 'trims UTC query padding by local onset year, keeping both local boundaries' do
    zone = TZInfo::Timezone.get('America/Santiago')
    reference = DateTime.new(2026, 10, 7)
    transition_type = Struct.new(:local_end)
    before = transition_type.new(DateTime.new(2025, 12, 31, 23))
    first = transition_type.new(DateTime.new(2026, 1, 1))
    last = transition_type.new(DateTime.new(2053, 12, 31, 23))
    after = transition_type.new(DateTime.new(2054, 1, 1))
    expect(zone).to receive(:transitions_up_to).
      with(Time.utc(2054, 1, 3), Time.utc(2025, 12, 30)).
      and_return([before, first, last, after])
    expect(Icalendar::TransitionRuleSample).to receive(:rules).
      with([first, last], anything, 2026, 28).and_return(nil)

    zone.ical_timezone(reference)
  end

  it 'retains the legacy path when transitions_up_to is unavailable' do
    zone = TZInfo::Timezone.get('America/Santiago')
    reference = DateTime.new(2026, 10, 7)
    period = zone.period_for_local(reference)
    allow(zone).to receive(:respond_to?).and_call_original
    allow(zone).to receive(:respond_to?).with(:transitions_up_to).and_return(false)
    expect(zone).not_to receive(:transitions_up_to)
    generated = zone.ical_timezone(reference)
    expect(generated.daylights.first.rrule.first.value_ical).to eq(period.daylight.rrule.first.value_ical)
    expect(generated.standards.first.rrule.first.value_ical).to eq(period.standard.rrule.first.value_ical)
  end
end
