require 'spec_helper'

describe Icalendar::Parser do
  subject { described_class.new source, false }

  describe '#parse' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event.ics') }

    it 'returns an array of calendars' do
      expect(subject.parse).to be_instance_of Array
      expect(subject.parse.count).to eq 1
      expect(subject.parse[0]).to be_instance_of Icalendar::Calendar
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

  describe '#parse with bad line' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event_bad_line.ics') }

    it 'returns an array of calendars' do
      expect(subject.parse).to be_instance_of Array
      expect(subject.parse.count).to eq 1
      expect(subject.parse[0]).to be_instance_of Icalendar::Calendar
    end

    it 'properly splits multi-valued lines' do
      event = subject.parse.first.events.first
      expect(event.geo).to eq [37.386013,-122.0829322]
    end

    it 'saves params' do
      event = subject.parse.first.events.first
      expect(event.dtstart.ical_params).to eq('tzid' => ['US-Mountain'])
    end

    it 'tolerates the truncated time' do
      event = subject.parse.first.events.first
      expect(event.dtstart.value_ical).to eq('20050120T170000')
    end
  end
end
