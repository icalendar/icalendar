require 'spec_helper'

describe Icalendar::Parser do
  subject { described_class.new source, false }
  let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', fn) }

  describe '#parse' do
    context 'reversed_timezone.ics' do
      let(:fn) { 'reversed_timezone.ics' }

      it 'correctly parses the event timezone' do
        event = subject.parse.first.events.first
        expect(event.dtstart.utc_offset).to eq -25200
      end
    end

    context 'single_event.ics' do
      let(:fn) { 'single_event.ics' }

      it 'returns an array of calendars' do
        parsed = subject.parse
        expect(parsed).to be_instance_of Array
        expect(parsed.count).to eq 1
        expect(parsed[0]).to be_instance_of Icalendar::Calendar
      end

      it 'properly splits multi-valued lines' do
        event = subject.parse.first.events.first
        expect(event.geo).to eq [37.386013,-122.0829322]
      end

      it 'saves params' do
        event = subject.parse.first.events.first
        expect(event.dtstart.ical_params).to eq('tzid' => ['US-Mountain'])
      end
    end
    context 'recurrence.ics' do
      let(:fn) { 'recurrence.ics' }
      it 'correctly parses the exdate array' do
        event = subject.parse.first.events.first
        ics = event.to_ical
        expect(ics).to match 'EXDATE;VALUE=DATE:20120323,20130323'
      end
    end
    context 'event.ics' do
      let(:fn) { 'event.ics' }

      before { subject.component_class = Icalendar::Event }

      it 'returns an array of events' do
        parsed = subject.parse
        expect(parsed).to be_instance_of Array
        expect(parsed.count).to be 1
        expect(parsed[0]).to be_instance_of Icalendar::Event
      end
    end
    context 'events.ics' do
      let(:fn) { 'two_events.ics' }

      before { subject.component_class = Icalendar::Event }

      it 'returns an array of events' do
        events = subject.parse
        expect(events.count).to be 2
        expect(events.first.uid).to eq("bsuidfortestabc123")
        expect(events.last.uid).to eq("uid-1234-uid-4321")
      end
    end
    context 'tzid_search.ics' do
      let(:fn) { 'tzid_search.ics' }

      it 'correctly sets the weird tzid' do
        parsed = subject.parse
        event = parsed.first.events.first
        expect(event.dtstart.utc).to eq Time.parse("20180104T150000Z")
      end
    end
    context 'custom_component.ics' do
      let(:fn) { 'custom_component.ics' }

      it 'correctly handles custom named components' do
        parsed = subject.parse
        calendar = parsed.first
        expect(calendar.custom_component('x_event_series').size).to eq 1
        expect(calendar.custom_component('X-EVENT-SERIES').size).to eq 1
      end
    end
  end

  describe '#parse with bad line' do
    let(:fn) { 'single_event_bad_line.ics' }

    it 'returns an array of calendars' do
      parsed = subject.parse
      expect(parsed).to be_instance_of Array
      expect(parsed.count).to eq 1
      expect(parsed[0]).to be_instance_of Icalendar::Calendar
    end

    it 'properly splits multi-valued lines' do
      event = subject.parse.first.events.first
      expect(event.geo).to eq [37.386013,-122.0829322]
    end

    it 'saves params' do
      event = subject.parse.first.events.first
      expect(event.dtstart.ical_params).to eq('tzid' => ['US-Mountain'])
    end
  end

  describe 'missing date value parameter' do
    let(:fn) { 'single_event_bad_dtstart.ics' }

    it 'falls back to date type for dtstart' do
      event = subject.parse.first.events.first
      expect(event.dtstart).to be_kind_of Icalendar::Values::Date
    end
  end

  describe 'completely bad location value' do
    let(:fn) { 'single_event_bad_location.ics' }

    it 'falls back to string type for location' do
      event = subject.parse.first.events.first
      expect(event.location).to be_kind_of Icalendar::Values::Text
      expect(event.location.value).to eq "1000 Main St Example, State 12345"
    end
  end

  describe 'custom properties with tzid' do
    let(:fn) { 'tz_store_param_bug.ics' }

    it 'parses without error' do
      expect(subject.parse.first).to be_a Icalendar::Calendar
    end

    it 'can be output to ics and re-parsed without error' do
      cal = subject.parse.first
      new_cal = Icalendar::Parser.new(cal.to_ical, false).parse.first
      expect(new_cal).to be_a Icalendar::Calendar
    end
  end
end
