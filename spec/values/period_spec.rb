require 'spec_helper'
require 'ostruct'

describe Icalendar::Values::Period do

  subject { described_class.new value }

  context 'date-time/date-time' do
    let(:value) { '19830507T000600Z/20140128T201400Z' }

    describe '#value_ical' do
      specify { expect(subject.value_ical).to eq value }
    end
    describe '#period_start' do
      specify { expect(subject.period_start).to eq DateTime.new(1983, 5, 7, 0, 6) }
    end
    describe '#duration' do
      specify { expect(subject.duration).to be_nil }
    end
    describe '#explicit_end' do
      specify { expect(subject.explicit_end).to eq DateTime.new(2014, 01, 28, 20, 14) }
    end
  end

  context 'date-time/duration' do
    let(:value) { '19830507T000600Z/P1604W' }
    let(:duration) { Struct.new(:past, :weeks, :days, :hours, :minutes, :seconds) }
    let(:expected_duration) { duration.new(false, 1604, 0, 0, 0, 0) }

    describe '#value_ical' do
      specify { expect(subject.value_ical).to eq value }

      it 'allows updating duration' do
        subject.duration = 'PT30M'
        expect(subject.value_ical).to eq '19830507T000600Z/PT30M'
      end
    end
    describe '#period_start' do
      specify { expect(subject.period_start).to eq DateTime.new(1983, 5, 7, 0, 6) }
    end
    describe '#duration' do
      specify { expect(subject.duration.weeks).to eq 1604 }
    end
    describe '#explicit_end' do
      specify { expect(subject.explicit_end).to eq nil }
    end
  end
end