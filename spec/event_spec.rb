require 'spec_helper'

describe Icalendar::Event do

  describe '#dtstart' do
    context 'no parent' do
      it 'is invalid if not set' do
        subject.should_not be_valid
      end

      it 'is valid if set' do
        subject.dtstart = DateTime.now
        subject.should be_valid
      end
    end

    context 'with parent' do
      before(:each) { subject.parent = Icalendar::Calendar.new }

      it 'is invalid without method set' do
        subject.should_not be_valid
      end

      it 'is valid with parent method set' do
        subject.parent.ip_method = 'UPDATE'
        subject.should be_valid
      end
    end
  end

  context 'mutually exclusive values' do
    before(:each) { subject.dtstart = DateTime.now }

    it 'is invalid if both dtend and duration are set' do
      subject.dtend = Date.today + 1;
      subject.duration = 'PT15M'
      subject.should_not be_valid
    end

    it 'is valid if dtend is set' do
      subject.dtend = Date.today + 1;
      subject.should be_valid
    end

    it 'is valid if duration is set' do
      subject.duration = 'PT15M'
      subject.should be_valid
    end
  end

  context 'suggested single values' do
    before(:each) do
      subject.dtstart = DateTime.now
      subject.append_rrule double('RRule')
      subject.append_rrule double('RRule')
    end

    it 'is valid by default' do
      subject.should be_valid
    end

    it 'is invalid with strict checking' do
      expect(subject.valid?(true)).to be_false
    end
  end

  context 'multi values' do
    describe '#comment' do
      it 'will return an array when set singly' do
        subject.comment = 'a comment'
        subject.comment.should == ['a comment']
      end

      it 'can be appended' do
        subject.comment << 'a comment'
        subject.comment << 'b comment'
        subject.comment.should == ['a comment', 'b comment']
      end

      it 'can be added' do
        subject.append_comment 'a comment'
        subject.comment.should == ['a comment']
      end
    end
  end

  describe '#find_alarm' do
    it 'should not respond_to find_alarm' do
      expect(subject.respond_to?(:find_alarm)).to be_false
    end
  end

  describe '#to_ical' do
    before(:each) do
      subject.dtstart = "20131227T013000Z"
      subject.dtend = "20131227T033000Z"
      subject.summary = 'My event, my ical, my test'
      subject.geo = [41.230896,-74.411774]
      subject.x_custom_property = 'customize'
    end

    it { expect(subject.to_ical).to include 'DTSTART:20131227T013000Z' }
    it { expect(subject.to_ical).to include 'DTEND:20131227T033000Z' }
    it { expect(subject.to_ical).to include 'SUMMARY:My event\, my ical\, my test' }
    it { expect(subject.to_ical).to include 'X-CUSTOM-PROPERTY:customize' }
    it { expect(subject.to_ical).to include 'GEO:41.230896;-74.411774' }
  end
end
