require 'spec_helper'

describe Icalendar::Freebusy do

  describe 'parse free bussys' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'freebusys.ics') }
    let(:cals  ) { Icalendar.parse(source, true) }
    
    it 'will have multiple freebusys entries' do
      expect(cals.freebusys.length).to eq 3
    end
    
    it 'freebusy will have a summary' do
      expect(cals.freebusys.first.summary).to eq "Busy"
    end

  end

end