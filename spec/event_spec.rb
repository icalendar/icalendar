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

  context 'mutually exclusive properties' do
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

  context 'suggested single properties' do
    before(:each) do
      subject.dtstart = DateTime.now
      subject.add_rrule double('RRule')
      subject.add_rrule double('RRule')
    end

    it 'is valid by default' do
      subject.should be_valid
    end

    it 'is invalid with strict checking' do
      expect(subject.valid?(true)).to be_false
    end
  end

  context 'multi properties' do
    describe '#comment' do
      it 'will return an array when set singly' do
        subject.comment = 'a comment'
        subject.comment.should == ['a comment']
      end

      it 'can be set with an array' do
        subject.comment = ['a comment']
        subject.comment.should == ['a comment']
      end

      it 'can be appended' do
        subject.comment << 'a comment'
        subject.comment << 'b comment'
        subject.comment.should == ['a comment', 'b comment']
      end

      it 'can be added' do
        subject.add_comment 'a comment'
        subject.comment.should == ['a comment']
      end
    end
  end

  describe '#find_alarm' do
    it 'should not respond_to find_alarm' do
      expect(subject.respond_to?(:find_alarm)).to be_false
    end
  end
end
