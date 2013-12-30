require 'spec_helper'

describe Icalendar do

  describe 'round-trip' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event.ics') }

    it 'will generate the same file as is parsed' do
      Icalendar.parse(source, true).to_ical.should == source
    end
  end
end
