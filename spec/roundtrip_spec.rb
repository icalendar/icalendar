require 'spec_helper'

describe Icalendar do

  describe 'single event round trip' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event.ics') }

    it 'will generate the same file as is parsed' do
      Icalendar.parse(source, true).to_ical.should == source
    end
  end

  describe 'timezone round trip' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'timezone.ics') }
    it 'will generate the same file as it parsed' do
      Icalendar.parse(source, true).to_ical.should == source
    end
  end

  describe 'non-default values' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'nondefault_values.ics') }
    subject { Icalendar.parse(source, true).events.first }

    it 'will set dtstart to Date' do
      expect(subject.dtstart.value).to eq ::Date.new(2006, 12, 15)
    end

    it 'will set dtend to Date' do
      expect(subject.dtend.value).to eq ::Date.new(2006, 12, 15)
    end

    it 'will output value param on dtstart' do
      expect(subject.dtstart.to_ical(subject.class.default_property_types['dtstart'])).to match /^;VALUE=DATE:20061215$/
    end

    it 'will output value param on dtend' do
      expect(subject.dtend.to_ical(subject.class.default_property_types['dtend'])).to match /^;VALUE=DATE:20061215$/
    end
  end

  describe 'non-standard values' do
    if defined? File::NULL
      before(:all) { Icalendar.logger = Icalendar::Logger.new File::NULL }
      after(:all) { Icalendar.logger = nil }
    end
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'nonstandard.ics') }
    subject { Icalendar::Parser.new(source, strict) }

    context 'strict parser' do
      let(:strict) { true }
      specify { expect { subject.parse }.to raise_error }
    end

    context 'lenient parser' do
      let(:strict) { false }
      specify { expect { subject.parse }.to_not raise_error }

      context 'saves non-standard fields' do
        let(:parsed) { subject.parse.first.events.first }
        specify { expect(parsed.custom_property('customfield').first).to eq 'Not properly noted as custom with X- prefix.' }
        specify { expect(parsed.custom_property('CUSTOMFIELD').first).to eq 'Not properly noted as custom with X- prefix.' }
      end

      it 'can output custom fields' do
        ical = subject.parse.first.to_ical
        expect(ical).to include 'CUSTOMFIELD:Not properly noted as custom with X- prefix.'
      end
    end
  end
end
