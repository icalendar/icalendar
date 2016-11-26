require 'spec_helper'

describe Icalendar::Freebusy do

  # currently no behavior in Journal not tested other places
  describe '#freebusys' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'freebusys.ics') }
    let(:cals  ) { Icalendar.parse(source) }
    
    it 'returns an array of calendars' do
      expect(cals      ).to be_instance_of Array
      expect(cals.count).to eq 1
      expect(cals.first).to be_instance_of Icalendar::Calendar
    end
    
    it 'returns an array of freebusys' do
      expect(cals.first.freebusys.count).to eq 3
    end
    
    it 'returns summary property for freebusy' do
      expect(cals.first.freebusys.first.summary).to eq "Busy"
    end

  end

end