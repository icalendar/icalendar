require 'spec_helper'

describe Icalendar::Timezone do

  describe "valid?" do
    subject { described_class.new.tap { |t| t.tzid = 'Eastern' } }

    context 'with both standard and daylight components' do
      before(:each) do
        subject.daylight { |d| d.should_receive(:valid?).and_return true }
        subject.standard { |s| s.should_receive(:valid?).and_return true }
      end

      it { should be_valid }
    end

    context 'with only standard' do
      before(:each) { subject.standard { |s| s.stub(:valid?).and_return true } }
      it { should be_valid }
    end

    context 'with only daylight' do
      before(:each) { subject.daylight { |d| d.stub(:valid?).and_return true } }
      it { should be_valid }
    end

    context 'with neither standard or daylight' do
      it { should_not be_valid }
    end
  end
end