require 'spec_helper'

describe Icalendar::Values::Recur do

  subject { described_class.new value }
  let(:value) { 'FREQ=DAILY' }

  describe 'parsing' do
    context 'multiple bydays' do
      let(:value) { 'FREQ=WEEKLY;COUNT=4;BYDAY=MO,WE,FR' }

      specify { expect(subject.frequency).to eq 'WEEKLY' }
      specify { expect(subject.count).to eq 4 }
      specify { expect(subject.by_day).to eq %w(MO WE FR) }
    end

    context 'single byday' do
      let(:value) { 'FREQ=YEARLY;BYDAY=2SU;BYMONTH=3' }

      specify { expect(subject.frequency).to eq 'YEARLY' }
      specify { expect(subject.by_day).to eq %w(2SU) }
      specify { expect(subject.by_month).to eq [3] }
    end

    context 'neverending yearly' do
      let(:value) { 'FREQ=YEARLY' }

      specify { expect(subject.frequency).to eq 'YEARLY' }
      it 'can be added to another event by sending' do
        event = Icalendar::Event.new
        event.send "rrule=", subject
        rule = event.send "rrule"
        expect(rule.first.frequency).to eq 'YEARLY'
      end
    end
  end

  describe '#valid?' do
    it 'requires frequency' do
      expect(subject.valid?).to be true
      subject.frequency = nil
      expect(subject.valid?).to be false
    end

    it 'cannot have both until and count' do
      subject.until = '20140201'
      subject.count = 4
      expect(subject.valid?).to be false
    end
  end

  describe '#value_ical' do
    let(:value) { 'FREQ=DAILY;BYYEARDAY=1,34,56,240;BYDAY=SU,SA' }

    it 'outputs in spec order' do
      expect(subject.value_ical).to eq 'FREQ=DAILY;BYDAY=SU,SA;BYYEARDAY=1,34,56,240'
    end
  end

  describe 'field access' do
    let(:value) { 'FREQ=WEEKLY;COUNT=4;BYDAY=MO,WE,FR' }

    it 'is backed by a Struct of the RRULE parts' do
      expect(subject.value).to be_a Icalendar::Values::Recur::Parts
      expect(subject.value.to_h).to include(frequency: 'WEEKLY', count: 4, by_day: %w(MO WE FR), until: nil)
    end

    it 'writes parts through setters' do
      subject.frequency = 'DAILY'
      subject.count = 2
      expect(subject.value_ical).to eq 'FREQ=DAILY;COUNT=2;BYDAY=MO,WE,FR'
    end

    it 'copies another recur' do
      expect(described_class.new(subject).value_ical).to eq subject.value_ical
    end
  end
end
